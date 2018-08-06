class CreateCopEventProgressStatuses < ActiveRecord::Migration[5.1]
  def change
    # 輸送イベント進捗情報
    create_table :cop_event_progress_statuses, id: :integer do |t|
      # 提督 ID
      t.integer  :admiral_id,          null: false

      # イベント No. （例：第壱回なら 1）
      t.integer  :event_no,            null: false

      # TPゲージの残量
      t.integer  :numerator,           null: false

      # TPゲージの最大数
      t.integer  :denominator,         null: false

      # 現在の周回数（1周目＝クリア周回数0の場合は1）
      t.integer  :achievement_number,  null: false

      # "全提督協力作戦 達成報酬獲得権利" の権利獲得済かどうか
      t.boolean  :area_achievement_claim, null: false, default: false

      # 限定フレームの所持数
      t.integer  :limited_frame_num,   null: false

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,         null: false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:admiral_id, :event_no, :exported_at], unique: true, name: 'index_cop_event_progress_statuses'
    end
  end
end
