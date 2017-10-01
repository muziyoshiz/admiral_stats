class AddDefOfActiveUsersToShipCardOwnerships < ActiveRecord::Migration[5.1]
  def change
    # アクティブユーザの定義を表す数値
    add_column :ship_card_ownerships, :def_of_active_users, :integer, after: :no_of_active_users, default: 0, null: false
  end
end
