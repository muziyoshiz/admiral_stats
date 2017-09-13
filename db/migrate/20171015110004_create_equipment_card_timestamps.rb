class CreateEquipmentCardTimestamps < ActiveRecord::Migration[5.1]
  def change
    # 装備図鑑のデータをインポートした時刻のタイムスタンプ
    # 新しい装備が何もない場合も、このテーブルのレコードだけは作成する
    create_table :equipment_card_timestamps, id: :integer do |t|
      # 提督 ID
      t.integer  :admiral_id,    null: false

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,   null: false

      t.index [:admiral_id, :exported_at], unique: true
    end
  end
end
