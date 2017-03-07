class CreateApiRequestLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :api_request_logs do |t|
      # 提督 ID
      t.integer  :admiral_id,      null: false

      # リクエスト URI
      t.string   :request_uri,     null: false,    limit: 255

      # ステータスコード
      t.integer  :status_code,     null: false

      # レスポンス内容を表すレスポンスボディなど
      t.string   :response,                        limit: 255

      # アクセス時刻
      t.datetime :created_at,      null: false
    end
  end
end
