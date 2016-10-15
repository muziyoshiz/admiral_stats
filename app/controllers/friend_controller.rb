class FriendController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: '友軍艦隊'
  end
end
