class CreateEventStageMasters < ActiveRecord::Migration[5.0]
  def change
    # 期間限定海域の各ステージのマスターデータ
    create_table :event_stage_masters do |t|
      # イベント No. （例：第壱回なら 1）
      t.integer  :event_no,               :null => false

      # 難易度（"HEI", "OTU", "KOU"）
      t.string   :level,                  :null => false, :limit => 32

      # ステージ No. （例：E-1 なら 1）
      t.integer  :stage_no,               :null => false

      # 作戦名
      t.string   :stage_mission_name,     :null => false, :limit => 32

      # 海域ゲージの最大値
      t.integer  :ene_military_gauge_val, :null => false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:event_no, :level, :stage_no], :unique => true, :name => 'index_event_stage_masters'
    end
  end
end
