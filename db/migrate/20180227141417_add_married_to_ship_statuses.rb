class AddMarriedToShipStatuses < ActiveRecord::Migration[5.1]
  def change
    add_column :ship_statuses, :married, :boolean, after: :blueprint_total_num, null: false, default: false
  end
end
