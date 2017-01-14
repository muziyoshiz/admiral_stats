class CreateShipSlotStatuses < ActiveRecord::Migration[5.0]
  def change
    create_table :ship_slot_statuses do |t|
      # このデータが紐付けられた ship_status の ID
      # 図鑑No.、改造レベル、エクスポート時刻は、ship_status からわかるので、このテーブルには格納しない
      t.integer :ship_status_id,  null: false

      # スロットの位置を表すインデックス（0〜3）
      t.integer :slot_index,      null: false

      # 装備名
      t.string  :slot_equip_name, null: false, limit: 32

      # 搭載可能な艦載機数
      t.integer :slot_amount,     null: false

      # 搭載状況を表す文字列を、対応する数値に変換したもの（0〜2）
      t.integer :slot_disp,       null: false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:ship_status_id, :slot_index], unique: true, name: 'index_ship_slot_statuses'
    end
  end
end
