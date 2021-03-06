# インポート処理に共通するメソッド
module Import
  extend ActiveSupport::Concern

  # admiral_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、1年分で 365 * 20 = 7,300
  # 上限に到達したユーザーが居るテーブルは、3年に緩和
  MAX_ADMIRAL_STATUSES_COUNT = 21900

  # ship_card_timestamps テーブルの、1 提督あたりのレコード数上限
  # admiral_statuses テーブルと同じ理由で、14600 とする。
  # 上限に到達したユーザーが居るテーブルは、3年に緩和
  MAX_SHIP_CARD_TIMESTAMPS_COUNT = 21900

  # ship_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、365 * 20 = 7,300
  # これが図鑑 No. の数だけ増える可能性があるため、365 * 20 * 350 = 2,555,000 とする。
  # 上限に到達したユーザーが居るテーブルは、2年に緩和
  MAX_SHIP_STATUSES_COUNT = 5110000

  # event_progress_statuses テーブルの、1 提督あたりのレコード数上限
  # イベント年4回、イベント期間1ヶ月、甲乙丙の3レベル、1日20回エクスポートしたと仮定して、
  # 1年分で 4 * 30 * 3 * 20 = 7200 とする。
  MAX_EVENT_PROGRESS_STATUSES_COUNT = 7200

  # blueprint_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、365 * 20 = 7,300
  # これが図鑑 No. の数だけ増える可能性があるため、365 * 20 * 350 = 2,555,000 とする。
  # 上限に到達したユーザーが居るテーブルは、2年に緩和
  MAX_BLUEPRINT_STATUSES_COUNT = 5110000

  # equipment_card_timestamps テーブルの、1 提督あたりのレコード数上限
  # admiral_statuses テーブルと同じ理由で、7300 とする。
  # 上限に到達したユーザーが居るテーブルは、3年に緩和
  MAX_EQUIPMENT_CARD_TIMESTAMPS_COUNT = 21900

  # equipment_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、365 * 20 = 7,300
  # これが図鑑 No. の数だけ増える可能性があるため、365 * 20 * 260 = 1,898,000 とする。
  MAX_EQUIPMENT_STATUSES_COUNT = 1898000

  # cop_event_progress_statuses テーブルの、1 提督あたりのレコード数上限
  # イベント年4回、イベント期間1ヶ月、1日20回エクスポートしたと仮定して、
  # 1年分で 4 * 30 * 20 = 2400 とする。
  MAX_COP_EVENT_PROGRESS_STATUSES_COUNT = 2400

  private

  # yyyymmdd_hhmmss 形式の時刻を、Time オブジェクト（JST）に変換します。
  def parse_time(timestamp)
    # JST として解釈したいが、strptime はタイムゾーンを指定できない
    # そのため、以下のページを参考に、変換処理を行った
    # 参考：http://qiita.com/sonots/items/2a318e1c9a52c0046751
    exported_at = Time.strptime(timestamp, '%Y%m%d_%H%M%S')
    utc_offset = exported_at.utc_offset
    zone_offset = Time.zone_offset('+09:00')

    exported_at.localtime(zone_offset) + utc_offset - zone_offset
  end

  # 基本情報の JSON データを元に、admiral_statuses レコードの追加
  # 返り値は、インポートの成否、およびメッセージ（またはエラーメッセージ）
  def save_admiral_statuses(admiral_id, exported_at, json, api_version)
    if AdmiralStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻の基本情報がインポート済みのため、無視されました。'
    end

    count = AdmiralStatus.where(admiral_id: admiral_id).count
    if count >= MAX_ADMIRAL_STATUSES_COUNT
      logger.error("Max admiral_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, '基本情報のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      AdmiralStatus.transaction do
        info = AdmiralStatsParser.parse_personal_basic_info(json, api_version)

        # first_and_create! も試したが、その場合は INSERT が行われなかった。エラーも発生しなかった。
        # また、INSERT されないにも関わらずインデックスのみが作られた。
        AdmiralStatus.create!(
            admiral_id: admiral_id,
            fuel: info.fuel,
            ammo: info.ammo,
            steel: info.steel,
            bauxite: info.bauxite,
            bucket: info.bucket,
            level: info.level,
            room_item_coin: info.room_item_coin,
            result_point: info.result_point,
            rank: info.rank,
            title_id: info.title_id,
            strategy_point: info.strategy_point,
            kou_medal: info.kou_medal,
            exported_at: exported_at,
        )
      end
    rescue => e
      logger.error(e)
      return :error, "基本情報のインポートに失敗しました。（原因：#{e.message}）"
    end

    return :created, '基本情報のインポートに成功しました。'
  end

  # 艦娘図鑑の JSON データを元に、ship_cards レコードの追加または更新
  def save_ship_cards(admiral_id, exported_at, json, api_version)
    # タイムスタンプが登録済みかどうか確認
    if ShipCardTimestamp.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻の艦娘図鑑がインポート済みのため、無視されました。'
    end

    count = ShipCardTimestamp.where(admiral_id: admiral_id).count
    if count >= MAX_SHIP_CARD_TIMESTAMPS_COUNT
      logger.error("Max ship_card_timestamps count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, '艦娘図鑑のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      # アップロードが同時並行で行われても first_exported_at の値が正しく設定されるように、
      # 分離レベルを :serializable に設定する。
      # これ以外の分離レベルでは、first_exported_at を、現在テーブルに格納されている値より
      # 大きな値に更新してしまうことが起こりうる。
      ShipCard.transaction(isolation: :serializable) do
        # その提督のカード情報を、最初にすべて取得
        ship_cards = ShipCard.where(admiral_id: admiral_id)

        AdmiralStatsParser.parse_tc_book_info(json, api_version).each do |info|
          info.card_img_list.each_with_index do |img, index|
            next if img.blank?

            ship_card = ship_cards.select{|c| c.book_no == info.book_no and c.card_index == index }.first
            if ship_card
              # レコードがすでにあり、エクスポート時刻がデータベース上の値より古ければ、更新
              if ship_card.first_exported_at > exported_at
                ship_card.first_exported_at = exported_at
                ship_card.save!
              end
            else
              # レコードがなければ新規作成
              ShipCard.create!(
                  admiral_id: admiral_id,
                  book_no: info.book_no,
                  card_index: index,
                  first_exported_at: exported_at,
              )
            end
          end
        end

        # すべての処理に成功したら、タイムスタンプを登録
        ShipCardTimestamp.create!( admiral_id: admiral_id, exported_at: exported_at )
      end
    rescue => e
      logger.error(e)
      return :error, "艦娘図鑑のインポートに失敗しました。（原因：#{e.message}）"
    end

    return :created, '艦娘図鑑のインポートに成功しました。'
  end

  # 艦娘一覧の JSON データを元に、ship_statuses レコードおよび ship_slot_statuses レコードの追加
  def save_ship_statuses(admiral_id, exported_at, json, api_version)
    if ShipStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻の艦娘一覧がインポート済みのため、無視されました。'
    end

    count = ShipStatus.where(admiral_id: admiral_id).count
    if count >= MAX_SHIP_STATUSES_COUNT
      logger.error("Max ship_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, '艦娘一覧のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      ShipStatus.transaction do
        AdmiralStatsParser.parse_character_list_info(json, api_version).each do |info|
          # 混乱を避けるため、boolean 型のカラムには NULL を許可せず、デフォルト値 false とする
          # info.married ||= false
          married = info.married || false

          # first_and_create! も試したが、その場合は INSERT が行われなかった。エラーも発生しなかった。
          # また、INSERT されないにも関わらずインデックスのみが作られた。
          status = ShipStatus.create!(
              admiral_id: admiral_id,
              book_no: info.book_no,
              remodel_level: info.remodel_lv,
              level: info.lv,
              star_num: info.star_num,
              exp_percent: info.exp_percent,
              blueprint_total_num: info.blueprint_total_num,
              married: married,
              exported_at: exported_at,
          )

          # API version 5 以上で、slot_num の値がある場合は、ship_slot_statuses レコードも保存する
          if info.slot_num and info.slot_num <= 4
            ShipSlotStatus.transaction do
              info.slot_num.times do |slot_index|
                ShipSlotStatus.create!(
                    ship_status_id: status.id,
                    slot_index: slot_index,
                    slot_equip_name: info.slot_equip_name[slot_index],
                    slot_amount: info.slot_amount[slot_index],
                    slot_disp: ShipSlotStatus.convert_slot_disp_to_i(info.slot_disp[slot_index])
                )
              end
            end
          end
        end
      end

    rescue => e
      logger.error(e)
      return :error, "艦娘一覧のインポートに失敗しました。（原因：#{e.message}）"
    end

    return :created, '艦娘一覧のインポートに成功しました。'
  end

  # イベント進捗情報の JSON データを元に、event_progress_statuses レコードの追加
  def save_event_progress_statuses(admiral_id, exported_at, json, api_version)
    if EventProgressStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻のイベント進捗情報がインポート済みのため、無視されました。'
    end

    count = EventProgressStatus.where(admiral_id: admiral_id).count
    if count >= MAX_EVENT_PROGRESS_STATUSES_COUNT
      logger.error("Max event_progress_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, 'イベント進捗情報のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      event_info_list = AdmiralStatsParser.parse_event_info(json, api_version)

      # イベント開催期間でない場合、event_info_list は空になる
      if event_info_list.blank?
        return :ok, 'イベント進捗情報が空のため、無視されました。'
      end

      # event_master に登録されていない area_id は拒否する
      area_id = event_info_list.map{|info| info.area_id }.max
      event = EventMaster.where(area_id: area_id).first
      unless event
        logger.warn("Unregistered area_id (admiral_id: #{admiral_id}, area_id: #{area_id})")
        return :ok, 'Admiral Stats にこのイベントの情報が未登録のため、無視されました。'
      end

      # period が nil の場合は、デフォルト値の 0 を設定する（第1回イベントのデータ形式への対応）
      event_info_list.each do |event_info|
        event_info.period ||= 0
      end

      # データがインポートされたかどうか確認するためのフラグ
      imported = false

      EventProgressStatus.transaction do
        event.periods.each do |period|
          event.levels_in_period(period).each do |level|
            summary = AdmiralStatsParser.summarize_event_info(event_info_list, level, period, api_version)

            # 上記の summary と同じ意味で、かつ exported_at が上記の summary よりも古いイベント進捗履歴が
            # 存在する場合は、インポートを行わない
            next if EventProgressStatus.where(
                'admiral_id = ? AND event_no = ? AND level = ? AND period = ? AND opened = ? AND current_loop_counts = ?' +
                    ' AND cleared_loop_counts = ? AND cleared_stage_no = ? AND current_military_gauge_left = ? AND exported_at <= ?',
                admiral_id, event.event_no, level, period, summary[:opened], summary[:current_loop_counts],
                summary[:cleared_loop_counts], summary[:cleared_stage_no], summary[:current_military_gauge_left], exported_at).exists?

            EventProgressStatus.create!(
                admiral_id: admiral_id,
                event_no: event.event_no,
                level: level,
                period: period,
                opened: summary[:opened],
                current_loop_counts: summary[:current_loop_counts],
                cleared_loop_counts: summary[:cleared_loop_counts],
                cleared_stage_no: summary[:cleared_stage_no],
                current_military_gauge_left: summary[:current_military_gauge_left],
                exported_at: exported_at,
            )
            imported = true
          end
        end
      end

      if imported
        return :created, 'イベント進捗情報のインポートに成功しました。'
      else
        return :ok, '同じ意味を持つ、過去のイベント進捗情報がインポート済みのため、無視されました。'
      end
    rescue => e
      logger.error(e)
      return :error, "イベント進捗情報のインポートに失敗しました。（原因：#{e.message}）"
    end
  end

  # 改装設計図一覧の JSON データを元に、blueprint_statuses レコードの追加
  def save_blueprint_statuses(admiral_id, exported_at, json, api_version)
    if BlueprintStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻の改装設計図一覧がインポート済みのため、無視されました。'
    end

    count = BlueprintStatus.where(admiral_id: admiral_id).count
    if count >= MAX_BLUEPRINT_STATUSES_COUNT
      logger.error("Max blueprint_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, '改装設計図一覧のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      BlueprintStatus.transaction do
        AdmiralStatsParser.parse_blueprint_list_info(json, api_version).each do |info|
          # 改装設計図一覧には、艦娘の図鑑 No. が含まれない
          # そのため、ship_master から図鑑 No. を検索する必要がある
          ship_master = ShipMaster.find_by_ship_name(info.ship_name)
          unless ship_master
            raise "Admiral Stats に艦娘 '#{info.ship_name}' が未登録です。プレイデータの誤登録を防ぐために、インポートを中断しました。"
          end

          info.expiration_date_list.each do |ed|
            # 有効期限（ミリ秒単位の UNIX タイムスタンプ）を、Time オブジェクト（JST）に変換
            expiration_date = Time.zone.at(ed.expiration_date / 1000)

            # first_and_create! も試したが、その場合は INSERT が行われなかった。エラーも発生しなかった。
            # また、INSERT されないにも関わらずインデックスのみが作られた。
            BlueprintStatus.create!(
                admiral_id: admiral_id,
                book_no: ship_master.book_no,
                expiration_date: expiration_date,
                blueprint_num: ed.blueprint_num,
                exported_at: exported_at,
            )
          end
        end
      end

    rescue => e
      logger.error(e)
      return :error, "改装設計図一覧のインポートに失敗しました。（原因：#{e.message}）"
    end

    return :created, '改装設計図一覧のインポートに成功しました。'
  end

  # 装備図鑑の JSON データを元に、equipment_cards レコードの追加または更新
  def save_equipment_cards(admiral_id, exported_at, json, api_version)
    # タイムスタンプが登録済みかどうか確認
    if EquipmentCardTimestamp.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻の装備図鑑がインポート済みのため、無視されました。'
    end

    count = EquipmentCardTimestamp.where(admiral_id: admiral_id).count
    if count >= MAX_EQUIPMENT_CARD_TIMESTAMPS_COUNT
      logger.error("Max equipment_card_timestamps count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, '装備図鑑のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      # アップロードが同時並行で行われても first_exported_at の値が正しく設定されるように、
      # 分離レベルを :serializable に設定する。
      # これ以外の分離レベルでは、first_exported_at を、現在テーブルに格納されている値より
      # 大きな値に更新してしまうことが起こりうる。
      EquipmentCard.transaction(isolation: :serializable) do
        # その提督のカード情報を、最初にすべて取得
        equipment_cards = EquipmentCard.where(admiral_id: admiral_id)

        AdmiralStatsParser.parse_equip_book_info(json, api_version).each do |info|
          # 未取得の装備に関するデータは登録しない
          # 未取得の場合は equipKind, equipName, equipImg が空になる
          next if info.equip_name.blank?

          card = equipment_cards.select{|c| c.book_no == info.book_no }.first
          if card
            # レコードがすでにあり、エクスポート時刻がデータベース上の値より古ければ、更新
            if card.first_exported_at > exported_at
              card.first_exported_at = exported_at
              card.save!
            end
          else
            # レコードがなければ新規作成
            EquipmentCard.create!(
                admiral_id: admiral_id,
                book_no: info.book_no,
                first_exported_at: exported_at,
            )
          end
        end

        # すべての処理に成功したら、タイムスタンプを登録
        EquipmentCardTimestamp.create!( admiral_id: admiral_id, exported_at: exported_at )
      end
    rescue => e
      logger.error(e)
      return :error, "装備図鑑のインポートに失敗しました。（原因：#{e.message}）"
    end

    return :created, '装備図鑑のインポートに成功しました。'
  end

  # 装備一覧の JSON データを元に、equipment_statuses レコードの追加
  def save_equipment_statuses(admiral_id, exported_at, json, api_version)
    if EquipmentStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻の装備一覧がインポート済みのため、無視されました。'
    end

    count = EquipmentStatus.where(admiral_id: admiral_id).count
    if count >= MAX_EQUIPMENT_STATUSES_COUNT
      logger.error("Max equipment_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, '装備一覧のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      EquipmentStatus.transaction do
        # マスターデータに含まれる equipment_id のリストを取得
        equipment_ids = EquipmentMaster.select(:equipment_id).reject{|e| e.equipment_id.nil? }.map(&:equipment_id)

        AdmiralStatsParser.parse_equip_list_info(json, api_version).each do |info|
          # 装備の equipment_id がマスターデータに含まれない場合は、ログにその装備の詳細を出力する
          unless equipment_ids.include?(info.equipment_id)
            logger.warn("Unknown equipment: equipment_id=#{info.equipment_id}, name=#{info.name}, type=#{info.type}")
          end

          # first_and_create! も試したが、その場合は INSERT が行われなかった。エラーも発生しなかった。
          # また、INSERT されないにも関わらずインデックスのみが作られた。
          EquipmentStatus.create!(
              admiral_id: admiral_id,
              equipment_id: info.equipment_id,
              num: info.num,
              exported_at: exported_at,
          )
        end
      end

    rescue => e
      logger.error(e)
      return :error, "装備一覧のインポートに失敗しました。（原因：#{e.message}）"
    end

    return :created, '装備一覧のインポートに成功しました。'
  end

  # 輸送イベント進捗情報の JSON データを元に、cop_event_progress_statuses レコードの追加
  def save_cop_event_progress_statuses(admiral_id, exported_at, json, api_version)
    if CopEventProgressStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      return :ok, '同じ時刻の輸送イベント進捗情報がインポート済みのため、無視されました。'
    end

    count = CopEventProgressStatus.where(admiral_id: admiral_id).count
    if count >= MAX_COP_EVENT_PROGRESS_STATUSES_COUNT
      logger.error("Max cop_event_progress_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return :error, '輸送イベント進捗情報のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
    end

    begin
      cop_info = AdmiralStatsParser.parse_cop_info(json, api_version)

      # イベント開催期間でない場合、cop_info は nil になる
      if cop_info.blank?
        return :ok, '輸送イベント進捗情報が空のため、無視されました。'
      end

      # cop_event_master に登録されていない area_id は拒否する
      area_id = cop_info.area_data_list.map{|area_data| area_data.area_id }.max
      cop_event = CopEventMaster.where(area_id: area_id).first
      unless cop_event
        logger.warn("Unregistered area_id (admiral_id: #{admiral_id}, area_id: #{area_id})")
        return :ok, 'Admiral Stats にこの輸送イベントの情報が未登録のため、無視されました。'
      end

      # データがインポートされたかどうか確認するためのフラグ
      imported = false

      CopEventProgressStatus.transaction do
        # 上記の cop_info と同じ意味で、かつ exported_at が上記の cop_info よりも古い輸送イベント進捗情報が
        # 存在する場合は、インポートを行わない
        unless CopEventProgressStatus.where(
            'admiral_id = ? AND event_no = ? AND numerator = ? AND denominator = ? AND achievement_number = ?' +
                ' AND area_achievement_claim = ? AND limited_frame_num = ? AND exported_at <= ?',
            admiral_id, cop_event.event_no, cop_info.numerator, cop_info.denominator, cop_info.achievement_number,
            cop_info.area_achievement_claim, cop_info.limited_frame_num, exported_at).exists?

          CopEventProgressStatus.create!(
              admiral_id: admiral_id,
              event_no: cop_event.event_no,
              numerator: cop_info.numerator,
              denominator: cop_info.denominator,
              achievement_number: cop_info.achievement_number,
              area_achievement_claim: cop_info.area_achievement_claim,
              limited_frame_num: cop_info.limited_frame_num,
              exported_at: exported_at,
          )
          imported = true
        end
      end

      if imported
        return :created, '輸送イベント進捗情報のインポートに成功しました。'
      else
        return :ok, '同じ意味を持つ、過去の輸送イベント進捗情報がインポート済みのため、無視されました。'
      end
    rescue => e
      logger.error(e)
      return :error, "輸送イベント進捗情報のインポートに失敗しました。（原因：#{e.message}）"
    end
  end
end
