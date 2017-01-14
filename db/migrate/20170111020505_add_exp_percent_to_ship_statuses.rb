class AddExpPercentToShipStatuses < ActiveRecord::Migration[5.0]
  def change
    # 経験値の獲得割合(%) (From API version 5)
    add_column :ship_statuses, :exp_percent, :integer, after: :star_num
  end
end
