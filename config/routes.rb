Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # 過去のお知らせ
  get 'notice', to: 'notice#index', as: :notice

  # 使い方
  get 'manual/exporter', to: 'manual#exporter'

  # インポート
  get 'import', to: 'import#index', as: :import
  post 'import/file', to: 'import#file'

  # 提督情報
  match 'admiral_info', to: 'admiral_info#index', via: [ :get, :post ]
  get 'admiral_info/event(/:event_no)', to: 'admiral_info#event'

  # 艦娘一覧
  get 'ship_list', to: 'ship_list#index'
  get 'ship_list/slot', to: 'ship_list#slot'

  # 艦娘情報
  match 'ship_info/level', to: 'ship_info#level', via: [ :get, :post ]
  match 'ship_info/level_summary', to: 'ship_info#level_summary', via: [ :get, :post ]
  match 'ship_info/card', to: 'ship_info#card', via: [ :get, :post ]

  # 全提督との比較
  get 'global/ship_card_ownership', to: 'global#ship_card_ownership'
  get 'global/ship_card_ownership/event/:event_no', to: 'global#event_ship_card_ownership'
  get 'global/event(/:event_no)', to: 'global#event'

  get 'friend', to: 'friend#index'

  # Admiral Stats について
  get 'about', to: 'about#index'

  # OmniAuth によるログイン・ログアウト
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'

  # デバッグ用のログイン（development のみ有効）
  get 'sessions/debug_create/:uid/:nickname', to: 'sessions#debug_create'

  # 以下の記載を追加すると root_url メソッドも自動設定される
  root to: 'home#index'

  # API
  scope 'api' do
    post 'import/:file_type/:timestamp', to: 'api_import#index', as: :api_import
  end

  # 上記のいずれにもマッチしなかった場合は、root にリダイレクト
  get '*unmatched_route', to: 'application#redirect_to_home'
end
