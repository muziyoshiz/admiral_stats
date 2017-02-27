class CreateAdmiralTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :admiral_tokens do |t|
      # 提督 ID
      t.integer  :admiral_id,      null: false

      # 認証トークン（JWT）
      t.string   :token,           null: false,    limit: 255

      # 発行時刻
      t.datetime :issued_at,       null: false
    end
  end
end
