class ManualController < ApplicationController
  def exporter
    set_meta_tags title: 'Admiral Stats の使い方'

    if logged_in?
      @token = AdmiralToken.where('admiral_id = ?', current_admiral.id).order(issued_at: :asc).first
    end

    # メニューバーまでキャッシュされてしまう（キャッシュ時のログイン状態のまま表示されてしまう）ため
    # キャッシュを無効化した。あとで、本文だけキャッシュするように直す。

    # 静的コンテンツのため、有効期限を設定
    # expires_in 1.hour

    # ブラウザにキャッシュさせたくない場合は以下のようにする
    # expires_now
  end
end
