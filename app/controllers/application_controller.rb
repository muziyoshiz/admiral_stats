class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # View でもメソッドを使えるようにするための設定
  helper_method :current_admiral, :logged_in?

  # routes.rb のみから参照されるメソッド（public に定義する必要あり）
  def redirect_to_home
    redirect_to controller: 'home', action: 'index'
  end

  private

  def current_admiral
    return unless session[:admiral_id]
    @current_admiral ||= Admiral.find(session[:admiral_id])
  end

  def logged_in?
    # !! は、返り値が nil の場合に、nil の代わりに false を返すための構文
    !!session[:admiral_id]
  end

  # before_action で認証状態をチェックするためのメソッド
  def authenticate
    return if logged_in?
    redirect_to root_path
  end

  # development 環境かどうかをチェックするためのメソッド
  def development_only
    return if Rails.env == 'development'
    redirect_to root_path
  end

  def jwt_current_admiral
    @jwt_current_admiral ||= Admiral.find(@jwt_admiral_id)
  end

  # Authorization ヘッダに含まれる JWT で認証状態をチェックするためのメソッド
  def jwt_authenticate
    unless jwt_bearer_token
      render json: { errors: [ { message: 'Unauthorized' }]}, status: :unauthorized
      return
    end

    unless jwt_decoded_token
      render json: { errors: [ { message: 'Invalid token' } ] }, status: :unauthorized
      return
    end

    unless @jwt_admiral_id
      # 有効期限の検査
      jwt_admiral_id = jwt_decoded_token[0]['id']
      if AdmiralToken.where(admiral_id: jwt_admiral_id, token: jwt_bearer_token).exists?
        @jwt_admiral_id = jwt_admiral_id
      else
        render json: { errors: [ { message: 'Expired token' } ] }, status: :unauthorized
      end
    end
  end

  # Authorization ヘッダの bearer 以下に含まれるトークンを返します。
  def jwt_bearer_token
    @jwt_bearer_token ||= if request.headers['Authorization'].present?
                      request.headers['Authorization'].split(' ').last
                    end
  end

  # JWT をデコードした結果を返します。
  def jwt_decoded_token
    begin
      @jwt_decoded_token ||= JWT.decode(
          jwt_bearer_token,
          Rails.application.secrets.secret_key_base,
          { :verify_iat => true, :algorithm => 'HS256' }
      )
    rescue JWT::DecodeError, JWT::VerificationError, JWT::InvalidIatError
      # エラーの詳細をクライアントには伝えないため、常に nil を返す
      # TODO デコード失敗のログの追加
      nil
    end
  end
end
