class PublicationController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: '情報公開の設定'
    @publication = AdmiralPublication.where('admiral_id = ?', current_admiral.id).first
    @publication ||= AdmiralPublication.new
  end

  def create_or_update
    set_meta_tags title: '情報公開の設定'

    begin
      AdmiralPublication.transaction do
        @publication = AdmiralPublication.where('admiral_id = ?', current_admiral.id).first

        if @publication
          @publication.update!(
              name: params[:publication][:name],
              url_name: params[:publication][:url_name],
              opens_twitter_nickname: params[:publication][:opens_twitter_nickname],
              opens_ship_list: params[:publication][:opens_ship_list]
          )
        else
          @publication = AdmiralPublication.create!(
              admiral_id: current_admiral.id,
              name: params[:publication][:name],
              url_name: params[:publication][:url_name],
              opens_twitter_nickname: params[:publication][:opens_twitter_nickname],
              opens_ship_list: params[:publication][:opens_ship_list]
          )
        end

        @messages = ['情報公開の設定の更新に成功しました。']
      end
    rescue => e
      logger.error(e)
      @error = "情報公開の設定の更新に失敗しました。（原因：#{e.message}）"
    end

    render action: 'index'
  end
end
