# インポート処理に共通するメソッド
module Import
  extend ActiveSupport::Concern

  # admiral_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、1年分で 365 * 20 = 7,300
  MAX_ADMIRAL_STATUSES_COUNT = 7300

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
  def save_admiral_statuses(admiral_id, exported_at, json, api_version, file_name = nil)
    if AdmiralStatus.where(admiral_id: admiral_id, exported_at: exported_at).exists?
      msg = '同じ時刻の基本情報がインポート済みのため、無視されました。'
      msg += "（ファイル名：#{file_name}）" if file_name
      return true, msg
    end

    count = AdmiralStatus.where(admiral_id: admiral_id).count
    if count >= MAX_ADMIRAL_STATUSES_COUNT
      logger.error("Max admiral_statuses count exceeded (admiral_id: #{admiral_id}, count: #{count})")
      return false, '基本情報のアップロード数が上限に達しました。心当たりがない場合は、サイトの不具合の可能性がありますので開発者にお問い合わせください。'
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
            exported_at: exported_at,
        )
      end
    rescue => e
      logger.debug(e)
      msg = "基本情報のインポートに失敗しました。（原因：#{e.message}）"
      msg += "（ファイル名：#{file_name}）" if file_name
      return false, msg
    end

    msg = '基本情報のインポートに成功しました。'
    msg += "（ファイル名：#{file_name}）" if file_name
    return true, msg
  end
end
