class ApiOriginalDataController < ApplicationController
  include Import

  before_action :jwt_authenticate

  # admiral_statuses テーブルの、1 提督あたりのレコード数上限
  # 1日20回（1時間に1回、メンテ時間除く）エクスポートしたと仮定して、1年分で 365 * 20 = 7,300
  MAX_ADMIRAL_STATUSES_COUNT = 7300

  # POST のボディ部に含まれる JSON をインポートする
  #
  # 以下の形式の JSON をレスポンスのデータ形式
  # {
  #   "data": {
  #     "message": "メッセージ"
  #   },
  #   "errors": [
  #     {
  #         "message": "エラーメッセージ"
  #     }
  #   ]
  # }
  def import
    # エクスポートしたファイル名のプレフィックスを受け取り、ファイル種別を判別する
    case params[:file_type]
      when 'Personal_basicInfo'
        file_type = :basic_info
      when 'TcBook_info'
        file_type = :ship_book
      when 'CharacterList_info'
        file_type = :ship_list
      when 'Event_info'
        file_type = :event_info
      else
        render json: { errors: [
            { message: "Unsupported file type: #{params[:file_type]}" }
        ]}
        return
    end

    # エクスポート時刻の取得
    if params[:timestamp] =~ /(\d{8}_\d{6})/
      exported_at = parse_time($1)
      api_version = AdmiralStatsParser.guess_api_version(exported_at)
    else
      render json: { errors: [
          { message: "Invalid timestamp: #{params[:timestamp]}" }
      ]}
      return
    end

    # ボディ部に含まれる JSON
    json = request.body.read

    res, msg = case file_type
      when :basic_info
        save_admiral_statuses(jwt_current_admiral.id, exported_at, json, api_version)
      when :ship_book
        save_ship_cards(jwt_current_admiral.id, exported_at, json, api_version)
      when :ship_list
        save_ship_statuses(jwt_current_admiral.id, exported_at, json, api_version)
      when :event_info
        save_event_progress_statuses(jwt_current_admiral.id, exported_at, json, api_version)
    end

    case res
      when :ok, :created
        render json: { data: { message: msg } }, status: res
      else
        render json: { errors: [ { message: msg } ] }
    end
  end
end
