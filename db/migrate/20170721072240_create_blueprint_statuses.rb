class CreateBlueprintStatuses < ActiveRecord::Migration[5.1]
  def change
    # 改装設計図一覧
    create_table :blueprint_statuses, id: :integer do |t|
      # 提督 ID
      t.integer  :admiral_id,          null: false

      # 艦娘図鑑の図鑑 No.
      t.integer  :book_no,             null: false

      # 有効期限が切れる月（有効期限が切れる月の 11日 23:59:59 の時刻が格納される）
      t.datetime :expiration_date,     null: false

      # その月に有効期限が切れる改装設計図の枚数
      t.integer  :blueprint_num,       null: false

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,         null: false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:admiral_id, :book_no, :expiration_date, :exported_at], unique: true, name: 'index_blueprint_statuses'
    end
  end
end
