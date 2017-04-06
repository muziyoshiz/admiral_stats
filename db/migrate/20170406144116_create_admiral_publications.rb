class CreateAdmiralPublications < ActiveRecord::Migration[5.0]
  def change
    create_table :admiral_publications do |t|
      # 提督 ID
      t.integer :admiral_id,              null: false

      # 公開する提督名（自己申告）
      t.string  :name,                    null: false,    limit: 32

      # 公開 URL に含める提督名
      t.string  :url_name,                null: false,    limit: 32

      # Twitter の nickname を公開するかどうか
      t.boolean :opens_twitter_nickname,  null: false,    default: false

      # 艦娘一覧を公開するかどうか
      t.boolean :opens_ship_list,         null: false,    default: false

      t.timestamps

      t.index :admiral_id, unique: true
      t.index :url_name, unique: true
    end
  end
end
