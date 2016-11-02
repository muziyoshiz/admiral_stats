class CreateEventMasters < ActiveRecord::Migration[5.0]
  def change
    # 期間限定海域のマスターデータ
    create_table :event_masters, id: false do |t|
      # イベント No. （例：第壱回なら 1）
      t.integer  :event_no,      null: false, primary_key: true

      # 期間限定海域名
      t.string   :event_name,    null: false, limit: 32

      # 開始時刻
      t.datetime :started_at,    null: false

      # 終了時刻
      t.datetime :ended_at,      null: false
    end
  end
end
