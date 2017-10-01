class ChangeIndexOfShipCardOwnerships < ActiveRecord::Migration[5.1]
  # change を使うと、MySQL では index の操作がうまくいかない（the limit is 64 characters エラーが出る）ため、
  # up と down を分けて定義した
  def up
    # インデックスの組合せに def_of_active_users を追加
    remove_index :ship_card_ownerships, name: 'index_ship_card_ownerships'
    add_index :ship_card_ownerships, [:book_no, :card_index, :def_of_active_users, :reported_at], unique: true, name: 'index_ship_card_ownerships'
  end

  def down
    remove_index :ship_card_ownerships, name: 'index_ship_card_ownerships'
    add_index :ship_card_ownerships, [:book_no, :card_index, :reported_at], unique: true, name: 'index_ship_card_ownerships'
  end
end
