class RequestLogController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: 'API ログの確認'

    # 最新 100 件まで表示
    @request_logs = ApiRequestLog.where(admiral_id: current_admiral.id).order(created_at: :desc).limit(100)
  end
end
