class CreateShipCardTimestamps < ActiveRecord::Migration[5.0]
  def change
    # 艦娘カードのデータをインポートした時刻のタイムスタンプ
    # 新しいカードが何もない場合も、このテーブルのレコードだけは作成する
    create_table :ship_card_timestamps do |t|
      # 提督 ID
      t.integer  :admiral_id,        :null => false

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,   :null => false

      t.index [:admiral_id, :exported_at], :unique => true
    end
  end
end
