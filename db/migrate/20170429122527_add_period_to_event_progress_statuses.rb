class AddPeriodToEventProgressStatuses < ActiveRecord::Migration[5.0]
  def change
    # 作戦
    add_column :event_progress_statuses, :period, :integer, after: :level, default: 0, null: false

    # インデックスに period を追加
    remove_index :event_progress_statuses, [:admiral_id, :event_no, :level, :exported_at]
    add_index :event_progress_statuses, [:admiral_id, :event_no, :level, :period, :exported_at], unique: true, name: 'index_event_progress_statuses'
  end
end
