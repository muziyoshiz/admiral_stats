class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # View でもメソッドを使えるようにするための設定
  helper_method :current_admiral, :logged_in?

  def redirect_to_home
    redirect_to home_url
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
end
