class CreateShipCards < ActiveRecord::Migration[5.0]
  def change
    # 艦娘カードの入手状況
    create_table :ship_cards do |t|
      # 提督 ID
      t.integer  :admiral_id,        :null => false

      # 艦娘図鑑の図鑑 No.
      t.integer  :book_no,           :null => false

      # 図鑑内のカードのインデックス（0〜5）
      t.integer  :card_index,        :null => false

      # SEGA の「提督情報」から最初にエクスポートされた日時
      # Admiral Stats へのアップロード時に指定されたタイムスタンプのうち、最も小さいもの
      t.datetime :first_exported_at, :null => false

      t.index [:admiral_id, :book_no, :card_index], :unique => true
    end
  end
end
