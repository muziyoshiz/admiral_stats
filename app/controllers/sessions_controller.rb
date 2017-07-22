class SessionsController < ApplicationController
  before_action :development_only, only: :debug_create

  def create
    admiral = Admiral.find_or_create_from_auth(request.env['omniauth.auth'])

    # admirals テーブルのレコードの作成・取得に失敗した場合
    unless admiral
      redirect_to root_path
      return
    end

    session[:admiral_id] = admiral.id
    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  # 任意のユーザを作成できるアクション
  # development 環境でのみ、実行を許可する
  def debug_create
    auth = {}
    auth[:provider] = 'twitter'
    auth[:uid] = params[:uid]
    auth[:info] = {}
    auth[:info][:nickname] = params[:nickname]

    admiral = Admiral.find_or_create_from_auth(auth)

    # admirals テーブルのレコードの作成・取得に失敗した場合
    unless admiral
      redirect_to root_path
      return
    end

    session[:admiral_id] = admiral.id
    redirect_to root_path
  end
end
