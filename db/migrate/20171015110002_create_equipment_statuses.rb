class CreateEquipmentStatuses < ActiveRecord::Migration[5.1]
  def change
    # 装備保有数
    create_table :equipment_statuses, id: :integer do |t|
      # 提督 ID
      t.integer  :admiral_id,      null: false

      # 装備一覧の装備 ID
      t.integer  :equipment_id,    null: false

      # 保有数
      t.integer  :num,             null: false

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,     null: false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:admiral_id, :equipment_id, :exported_at], unique: true, name: 'index_equipment_statuses'
    end
  end
end
