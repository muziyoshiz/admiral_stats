# インポート処理に共通するメソッド
module Import
  extend ActiveSupport::Concern

  # admiral_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、1年分で 365 * 20 = 7,300
  MAX_ADMIRAL_STATUSES_COUNT = 7300

  # ship_card_timestamps テーブルの、1 提督あたりのレコード数上限
  # admiral_statuses テーブルと同じ理由で、7300 とする。
  MAX_SHIP_CARD_TIMESTAMPS_COUNT = 7300

  # ship_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、365 * 20 = 7,300
  # これが図鑑 No. の数だけ増える可能性があるため、365 * 20 * 350 = 2,555,000 とする。
  MAX_SHIP_STATUSES_COUNT = 2555000

  # event_progress_statuses テーブルの、1 提督あたりのレコード数上限
  # イベント年4回、イベント期間1ヶ月、甲乙丙の3レベル、1日20回エクスポートしたと仮定して、
  # 1年分で 4 * 30 * 3 * 20 = 7200 とする。
  MAX_EVENT_PROGRESS_STATUSES_COUNT = 7200

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

      # event_master に登録されていない event_no は拒否する
      event_no = event_info_list.map{|info| info.event_no }.max
      event = EventMaster.where(event_no: event_no).first
      unless event
        logger.error("Unregistered event_no (admiral_id: #{admiral_id}, event_no: #{event_no})")
        return :error, 'Admiral Stats にこのイベントの情報が未登録です。プレイデータの誤登録を防ぐために、インポートを中断しました。'
      end

      # データがインポートされたかどうか確認するためのフラグ
      imported = false

      EventProgressStatus.transaction do
        # TODO このループを、すべての難易度と作戦（前段/後段）の組み合わせに対して実行する
        event.levels.each do |level|
          summary = AdmiralStatsParser.summarize_event_info(event_info_list, level, api_version)

          # 上記の summary と同じ意味で、かつ exported_at が上記の summary よりも古いイベント進捗履歴が
          # 存在する場合は、インポートを行わない
          next if EventProgressStatus.where(
              'admiral_id = ? AND event_no = ? AND level = ? AND opened = ? AND current_loop_counts = ?' +
                  ' AND cleared_loop_counts = ? AND cleared_stage_no = ? AND current_military_gauge_left = ? AND exported_at <= ?',
              admiral_id, event_no, level, summary[:opened], summary[:current_loop_counts],
              summary[:cleared_loop_counts], summary[:cleared_stage_no], summary[:current_military_gauge_left], exported_at).exists?

          EventProgressStatus.create!(
              admiral_id: admiral_id,
              event_no: event_no,
              level: level,
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
end
