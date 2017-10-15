class CreateEquipmentMasters < ActiveRecord::Migration[5.1]
  def change
    create_table :equipment_masters, id: false do |t|
      # 装備図鑑の図鑑 No.
      t.integer  :book_no,             null: false, primary_key: true

      # 装備一覧の装備 ID
      # 図鑑 No. と異なる場合があるので、事前にわからない。未知の装備の場合は NULL
      t.integer  :equipment_id,        null: true,  unique: true

      # 装備種別
      # SEGA 公式サイトから返される文字よりも、装備種別を細かく表したもの
      t.string   :equipment_type,      null: false, limit: 32

      # 装備名
      t.string   :equipment_name,      null: false, limit: 32

      # 装備のレアリティを表す星の数
      t.integer  :star_num,            null: false

      # 艦これアーケードで実装された日時
      # 未実装の場合は NULL
      t.datetime :implemented_at
    end
  end
end
