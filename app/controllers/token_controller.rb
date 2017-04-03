class TokenController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: 'API トークンの設定'
    @token = AdmiralToken.where('admiral_id = ?', current_admiral.id).order(issued_at: :asc).first
  end

  def create
    set_meta_tags title: 'API トークンの設定'

    begin
      AdmiralToken.transaction do
        AdmiralToken.where('admiral_id = ?', current_admiral.id).delete_all

        issued_at = Time.now
        token = JWT.encode({ id: current_admiral.id, iat: issued_at.to_i }, Rails.application.secrets.secret_key_base, 'HS256')

        AdmiralToken.create!(
            admiral_id: current_admiral.id,
            token: token,
            issued_at: issued_at
        )
      end
    rescue => e
      logger.error(e)
      @error = "トークンの発行に失敗しました。（原因：#{e.message}）"
    end

    @token = AdmiralToken.where('admiral_id = ?', current_admiral.id).order(issued_at: :asc).first
    render action: 'index'
  end
end
