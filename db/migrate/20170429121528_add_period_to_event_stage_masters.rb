class AddPeriodToEventStageMasters < ActiveRecord::Migration[5.0]
  def change
    # 作戦
    add_column :event_stage_masters, :period, :integer, after: :level, default: 0, null: false
    # 表示用のステージ No.
    add_column :event_stage_masters, :display_stage_no, :integer, after: :stage_no, default: 0, null: false

    # インデックスに period を追加
    remove_index :event_stage_masters, [:event_no, :level, :stage_no]
    add_index :event_stage_masters, [:event_no, :level, :period, :stage_no], unique: true, name: 'index_event_stage_masters'
  end
end
