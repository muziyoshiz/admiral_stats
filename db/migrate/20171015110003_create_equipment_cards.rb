class CreateEquipmentCards < ActiveRecord::Migration[5.1]
  def change
    create_table :equipment_cards, id: :integer do |t|
      # 提督 ID
      t.integer  :admiral_id,        null: false

      # 装備図鑑の図鑑 No.
      t.integer  :book_no,           null: false

      # SEGA の「提督情報」から最初にエクスポートされた日時
      # Admiral Stats へのアップロード時に指定されたタイムスタンプのうち、最も小さいもの
      t.datetime :first_exported_at, null: false

      t.index [:admiral_id, :book_no], unique: true
    end
  end
end
