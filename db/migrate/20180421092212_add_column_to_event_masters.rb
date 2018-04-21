class AddColumnToEventMasters < ActiveRecord::Migration[5.1]
  def change
    # EO の開始日時
    add_column :event_masters, :period2_started_at, :datetime, after: :period1_started_at, null: true
  end
end
