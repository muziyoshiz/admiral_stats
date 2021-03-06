class ApiImportController < ApplicationController
  include Import

  # API 用のコントローラでは CSRF 対策を無効化する
  skip_before_action :verify_authenticity_token

  before_action :jwt_authenticate

  # Admiral Stats がインポート可能なファイル種別のリスト（パスの区切り / を _ に置換済み）
  SUPPORTED_FILE_TYPES = [
      'Personal_basicInfo',
      'TcBook_info',
      'CharacterList_info',
      'Event_info',
      'BlueprintList_info',
      'EquipBook_info',
      'EquipList_info',
      'Cop_info'
  ]

  # Admiral Stats がインポート可能なファイル種別のリスト（パスの区切り / を _ に置換済み）を返します。
  def file_types
    record_api_request_log(:ok)
    render json: SUPPORTED_FILE_TYPES
  end

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
      when 'BlueprintList_info'
        file_type = :blueprint_list
      when 'EquipBook_info'
        file_type = :equip_book
      when 'EquipList_info'
        file_type = :equip_list
      when 'Cop_info'
        file_type = :cop_info
      else
        msg = "Admiral Stats がインポートできないファイル種別のため、無視されました。（ファイル種別：#{params[:file_type]}）"
        record_api_request_log(:ok, msg)
        render json: { data: { message: msg } }
        return
    end

    # エクスポート時刻の取得
    if params[:timestamp] =~ /(\d{8}_\d{6})/
      exported_at = parse_time($1)
      api_version = AdmiralStatsParser.guess_api_version(exported_at)
    else
      msg = "タイムスタンプの形式が不正です。（タイムスタンプ：#{params[:timestamp]}）"
      record_api_request_log(:bad_request, msg)
      render json: { errors: [ { message: msg } ] }, status: :bad_request
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
                 when :blueprint_list
                   save_blueprint_statuses(jwt_current_admiral.id, exported_at, json, api_version)
                 when :equip_book
                   save_equipment_cards(jwt_current_admiral.id, exported_at, json, api_version)
                 when :equip_list
                   save_equipment_statuses(jwt_current_admiral.id, exported_at, json, api_version)
                 when :cop_info
                   save_cop_event_progress_statuses(jwt_current_admiral.id, exported_at, json, api_version)
               end

    record_api_request_log(res, msg)

    case res
      when :ok, :created
        render json: { data: { message: msg } }, status: res
      else
        render json: { errors: [ { message: msg } ] }, status: :bad_request
    end
  end

  private

  # api_request_logs テーブルに API リクエストログを記録します。
  def record_api_request_log(res, msg = nil)
    # 記録に失敗しても、ログに記録するだけで、リクエストの処理は継続する
    begin
      # エラーメッセージを返す場合（res == :error）は 200 として記録
      status_code = (res == :error) ? 200 : Rack::Utils::SYMBOL_TO_STATUS_CODE[res]

      # ステータスコードを integer に変換してから記録
      # http://www.rubydoc.info/github/rack/rack/Rack/Utils
      ApiRequestLog.create!(
          admiral_id: jwt_current_admiral.id,
          request_method: request.request_method,
          request_uri: request.original_url,
          user_agent: request.user_agent,
          status_code: status_code,
          response: msg,
      )
    rescue => e
      logger.error(e)
      logger.error("res: #{res}, msg: #{msg}")
    end
  end
end
