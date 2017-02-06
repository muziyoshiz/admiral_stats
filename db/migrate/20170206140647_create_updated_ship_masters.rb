class CreateUpdatedShipMasters < ActiveRecord::Migration[5.0]
  def change
    # 後から更新された艦娘情報のマスターデータ
    # 現時点では、「改」カードだけが後から実装される、というパターンのみが存在する
    create_table :updated_ship_masters, id: false do |t|
      # 図鑑 No.
      t.integer :book_no,          null: false, primary_key: true

      # 艦型
      t.string  :ship_class,       null: false, limit: 32

      # 艦番号
      t.integer :ship_class_index, null: false

      # 艦種
      t.string  :ship_type,        null: false, limit: 32

      # 艦名
      t.string  :ship_name,        null: false, limit: 32

      # 画像（カード）のバリエーション数
      t.integer :variation_num,    null: false

      # ノーマルカードの改造レベルを表す数値
      # この値が 1 の場合は、図鑑の 1 枚目のカードが改
      t.integer :remodel_level,    null: false, default: 0

      # 艦これアーケードで実装された日時
      # updated_ship_master の場合は、必ず NULL 以外になる
      t.datetime :implemented_at,  null: false
    end
  end
end
