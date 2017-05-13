class CreateSpecialShipMasters < ActiveRecord::Migration[5.0]
  def change
    create_table :special_ship_masters do |t|
      # 追加されたカードの図鑑 No.
      t.integer  :book_no,         null: false

      # 追加されたカードの図鑑内でのインデックス（0〜）
      t.integer  :card_index,      null: false

      # 追加されたカードの改造レベルを表す数値
      # 0 ならノーマル、1 から改
      t.integer  :remodel_level,   null: false, default: 0

      # 追加されたカードのレアリティを表す数値
      # 0: ノーマル相当
      # 1: ホロ相当（運が上がる）
      # 2: 中破相当（運が上がり、装甲が下がる）
      t.integer  :rarity,          null: false, default: 0

      # 艦これアーケードで実装された日時
      t.datetime :implemented_at

      t.index [:book_no, :card_index], unique: true
    end
  end
end
