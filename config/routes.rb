Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # 過去のお知らせ
  get 'notice', to: 'notice#index', as: :notice

  # 使い方
  get 'manual/exporter', to: 'manual#exporter'

  # インポート
  get 'import', to: 'import#index', as: :import
  post 'import/file', to: 'import#file'
  post 'import/generate_token', to: 'import#generate_token'

  # 提督情報
  match 'admiral_info', to: 'admiral_info#index', via: [ :get, :post ]
  get 'admiral_info/event(/:event_no(/:period))', to: 'admiral_info#event'

  # 艦娘情報
  ## 表が主体のページ
  get 'ship_list', to: 'ship_list#index'
  get 'ship_list/slot', to: 'ship_list#slot'
  get 'ship_list/blueprint', to: 'ship_list#blueprint'
  ## グラフが主体のページ
  match 'ship_info/level', to: 'ship_info#level', via: [ :get, :post ]
  match 'ship_info/level_summary', to: 'ship_info#level_summary', via: [ :get, :post ]
  match 'ship_info/card', to: 'ship_info#card', via: [ :get, :post ]

  # 装備情報
  ## 表が主体のページ
  get 'equipment_list', to: 'equipment_list#index'
  ## グラフが主体のページ

  # 全提督との比較
  get 'global/ship_card_ownership', to: 'global#ship_card_ownership', as: :global_ship_card_ownership
  get 'global/ship_card_ownership/active/:def_of_active_users', to: 'global#ship_card_ownership'
  get 'global/ship_card_ownership/event/:event_no', to: 'global#event_ship_card_ownership'
  get 'global/event(/:event_no(/:period))', to: 'global#event'

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

  # Public play data
  scope '/@:url_name' do
    # 公開情報の種類が2種類以上になったら、リダイレクト処理を変更する
    get '/', to: redirect('/@%{url_name}/ship_list')
    get '/ship_list', to: 'public_ship_list#index'
  end
  # 古い URL を、互換性維持のために残す
  get 'admirals/:url_name/ship_list', to: redirect('/@%{url_name}'), constraints: { format: :html }

  # Settings
  scope 'settings' do
    get 'request_logs', to: 'request_log#index'
    get 'tokens', to: 'token#index'
    post 'tokens', to: 'token#create'
    get 'publications', to: 'publication#index'
    post 'publications', to: 'publication#create_or_update'
  end

  # API
  scope 'api/v1' do
    # Admiral Stats がインポート可能なファイル種別のリスト（snake_case）
    get 'import/file_types', to: 'api_import#file_types'

    # SEGA 公式からエクスポートしたプレイデータのインポート
    post 'import/:file_type/:timestamp', to: 'api_import#import', as: :api_import
  end

  # 上記のいずれにもマッチしなかった場合は、root にリダイレクト
  get '*unmatched_route', to: 'application#redirect_to_home'
end
