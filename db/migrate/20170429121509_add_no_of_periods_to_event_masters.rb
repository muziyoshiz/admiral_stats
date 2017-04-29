class AddNoOfPeriodsToEventMasters < ActiveRecord::Migration[5.0]
  def change
    # 作戦数（通常は1、多段作戦の場合は2以上）
    add_column :event_masters, :no_of_periods, :integer, after: :event_name, default: 1, null: false
    # 後段作戦の開始日時
    add_column :event_masters, :period1_started_at, :datetime, after: :no_of_periods, null: true
  end
end
