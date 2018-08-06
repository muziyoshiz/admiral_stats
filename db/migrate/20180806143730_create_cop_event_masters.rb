class CreateCopEventMasters < ActiveRecord::Migration[5.1]
  def change
    # 輸送イベント（期間限定作戦）のマスターデータ
    create_table :cop_event_masters, id: false do |t|
      # イベント No. （例：第1回なら 1）
      t.integer  :event_no,      null: false, primary_key: true

      # 海域番号
      t.integer  :area_id,       null: false, unique: true

      # 期間限定海域名
      t.string   :event_name,    null: false, limit: 32

      # 開始時刻
      t.datetime :started_at,    null: false

      # 終了時刻
      t.datetime :ended_at,      null: false
    end
  end
end
