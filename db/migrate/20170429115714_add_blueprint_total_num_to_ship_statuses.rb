class AddBlueprintTotalNumToShipStatuses < ActiveRecord::Migration[5.0]
  def change
    # 改装設計図の枚数 (From API version 7)
    add_column :ship_statuses, :blueprint_total_num, :integer, after: :exp_percent
  end
end
