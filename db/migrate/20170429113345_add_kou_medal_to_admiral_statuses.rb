class AddKouMedalToAdmiralStatuses < ActiveRecord::Migration[5.0]
  def change
    # 甲種勲章の数 (From API version 7)
    add_column :admiral_statuses, :kou_medal, :integer, after: :strategy_point
  end
end
