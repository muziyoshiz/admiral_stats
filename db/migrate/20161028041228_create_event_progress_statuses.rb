class CreateEventProgressStatuses < ActiveRecord::Migration[5.0]
  def change
    # イベント進捗情報
    create_table :event_progress_statuses do |t|
      # 提督 ID
      t.integer  :admiral_id,          :null => false

      # イベント No. （例：第壱回なら 1）
      t.integer  :event_no,            :null => false

      # 難易度（HEI, OTU, KOU）
      t.string   :level,               :null => false, :limit => 8

      # 現在の周回数（1 〜）
      t.integer  :current_loop_counts, :null => false

      # 最終ステージまで攻略済みの周回数（0 〜）
      t.integer  :cleared_loop_counts, :null => false

      # 現在の周回で攻略済みのステージ番号（0 〜）
      # E-1 未攻略なら 0
      # E-1 攻略済みなら、丙 E-1 でも、乙 E-1 でも 1
      t.integer  :cleared_stage_no,    :null => false

      # 攻略中のステージの海域ゲージの現在値
      # 全ステージ攻略後、および掃討戦攻略前の場合は 0
      t.integer  :current_military_gauge_left, :null => false

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,         :null => false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:admiral_id, :event_no, :level, :exported_at], :unique => true, :name => 'index_event_progress_statuses'
    end
  end
end
