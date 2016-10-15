class AddStarNumToShipStatuses < ActiveRecord::Migration[5.0]
  def change
    # 星の数 (From API version 3)
    add_column :ship_statuses, :star_num, :integer, :after => :level
  end
end
