class ImportController < ApplicationController
  before_action :authenticate

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

  def index
    set_meta_tags title: 'インポート'
  end

  # ファイルのアップロード
  def file
    set_meta_tags title: 'インポート'

    # エラーが発生した場合のみ、エラーメッセージが格納される変数
    @error = nil

    # 成功、または成功でも失敗でもないメッセージ
    # flash は上限が 4KB なので、すべてのメッセージを格納できない。
    # そのため、flash[:messages] を使う方式から、変数 @messages を使う方式に変更した。
    @messages = []

    files = params[:files]
    file_type = params[:file_type]

    if files.blank?
      @error = 'ファイルが指定されていません。'
      render :action => :index
      return
    end

    if file_type.nil?
      @error = '種別が指定されていません。'
      render :action => :index
      return
    end

    # タイムスタンプを取得できるか検査
    timestamps = {}
    files.each do |file|
      # ファイル名からタイムスタンプを取得
      file_name = file.original_filename
      if file_name =~ /(\d{8}_\d{6})/
        timestamps[file] = parse_time($1)
        logger.debug("exported_at: " + timestamps[file].to_s)
      else
        @error = "タイムスタンプが指定されていません。（ファイル名：#{file_name}）"
        render :action => :index
        return
      end
    end

    files.each do |file|
      # ファイル名の自動判別と、ログ出力のためにファイル名を取得
      file_name = file.original_filename

      # エクスポート時刻から API version を推測
      exported_at = timestamps[file]
      api_version = AdmiralStatsParser.guess_api_version(exported_at)

      json = file.read

      # file_type == 'auto' の場合は、ファイル種別の自動判別を行う
      ft = file_type
      if file_type == 'auto'
        case file_name
          when /^Personal_basicInfo_/
            ft = 'basic_info'
          when /^TcBook_info_/
            ft = 'ship_book'
          when /^CharacterList_info_/
            ft = 'ship_list'
          else
            @messages << "ファイル種別を自動判別できなかったため、無視されました。（ファイル名：#{file_name}）"
            next
        end
      end

      case ft
        when 'basic_info'
          succeeded = save_admiral_statuses(current_admiral.id, exported_at, json, api_version, file_name)
        when 'ship_book'
          succeeded = save_ship_cards(current_admiral.id, exported_at, json, api_version, file_name)
        when 'ship_list'
          succeeded = save_ship_statuses(current_admiral.id, exported_at, json, api_version, file_name)
      end

      break unless succeeded
    end

    render :action => :index
  end

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
  def save_admiral_statuses(admiral_id, exported_at, json, api_version, file_name)
    if AdmiralStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      @messages << "同じ時刻の基本情報がインポート済みのため、無視されました。（ファイル名：#{file_name}）"
      return true
    end

    count = AdmiralStatus.where(admiral_id: admiral_id).count
    if count >= MAX_ADMIRAL_STATUSES_COUNT
      logger.error("Max admiral_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count}")
      @error = '基本情報のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
      return false
    end

    begin
      AdmiralStatus.transaction do
        info = AdmiralStatsParser.parse_personal_basic_info(json, api_version)

        # first_and_create! も試したが、その場合は INSERT が行われなかった。エラーも発生しなかった。
        # また、INSERT されないにも関わらずインデックスのみが作られた。
        AdmiralStatus.create!(
            :admiral_id => admiral_id,
            :fuel => info.fuel,
            :ammo => info.ammo,
            :steel => info.steel,
            :bauxite => info.bauxite,
            :bucket => info.bucket,
            :level => info.level,
            :room_item_coin => info.room_item_coin,
            :result_point => info.result_point,
            :rank => info.rank,
            :title_id => info.title_id,
            :strategy_point => info.strategy_point,
            :exported_at => exported_at,
        )
      end

      @messages << "基本情報のインポートに成功しました。（ファイル名：#{file_name}）"
    rescue => e
      logger.debug(e)
      @error = "基本情報のインポートに失敗しました。（ファイル名：#{file_name}、原因：#{e.message}）"
      return false
    end

    true
  end

  # 艦娘図鑑の JSON データを元に、ship_cards レコードの追加または更新
  def save_ship_cards(admiral_id, exported_at, json, api_version, file_name)
    # タイムスタンプが登録済みかどうか確認
    if ShipCardTimestamp.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      @messages << "同じ時刻の艦娘図鑑がインポート済みのため、無視されました。（ファイル名：#{file_name}）"
      return true
    end

    count = ShipCardTimestamp.where(admiral_id: admiral_id).count
    if count >= MAX_SHIP_CARD_TIMESTAMPS_COUNT
      logger.error("Max ship_card_timestamps count exceeded (admiral_id: #{admiral_id}, count: #{count}")
      @error = '艦娘図鑑のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
      return false
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
                  :admiral_id => admiral_id,
                  :book_no => info.book_no,
                  :card_index => index,
                  :first_exported_at => exported_at,
              )
            end
          end
        end

        # すべての処理に成功したら、タイムスタンプを登録
        ShipCardTimestamp.create!( :admiral_id => admiral_id, :exported_at => exported_at )
      end

      @messages << "艦娘図鑑のインポートに成功しました。（ファイル名：#{file_name}）"
    rescue => e
      logger.debug(e)
      @error = "艦娘図鑑のインポートに失敗しました。（ファイル名：#{file_name}、原因：#{e.message}）"
      return false
    end

    true
  end

  # 艦娘一覧の JSON データを元に、ship_statuses レコードの追加
  def save_ship_statuses(admiral_id, exported_at, json, api_version, file_name)
    if ShipStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      @messages << "同じ時刻の艦娘一覧がインポート済みのため、無視されました。（ファイル名：#{file_name}）"
      return true
    end

    count = ShipStatus.where(admiral_id: admiral_id).count
    if count >= MAX_SHIP_STATUSES_COUNT
      logger.error("Max ship_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count}")
      @error = '艦娘一覧のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
      return false
    end

    begin
      ShipStatus.transaction do
        AdmiralStatsParser.parse_character_list_info(json, api_version).each do |info|
          # first_and_create! も試したが、その場合は INSERT が行われなかった。エラーも発生しなかった。
          # また、INSERT されないにも関わらずインデックスのみが作られた。
          ShipStatus.create!(
              :admiral_id => admiral_id,
              :book_no => info.book_no,
              :remodel_level => info.remodel_lv,
              :level => info.lv,
              :star_num => info.star_num,
              :exported_at => exported_at,
          )
        end
      end

      @messages << "艦娘一覧のインポートに成功しました。（ファイル名：#{file_name}）"
    rescue => e
      logger.debug(e)
      @error = "艦娘一覧のインポートに失敗しました。（ファイル名：#{file_name}、原因：#{e.message}）"
      return false
    end

    true
  end
end
