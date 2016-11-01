class CreateEventShipCardOwnerships < ActiveRecord::Migration[5.0]
  def change
    # 特定のイベント参加者に限定した、艦娘カードの所有者数の計測結果
    create_table :event_ship_card_ownerships do |t|
      # イベント No. （例：第壱回なら 1）
      t.integer  :event_no,           null: false

      # 艦娘図鑑の図鑑 No.
      t.integer  :book_no,            null: false

      # 図鑑内のカードのインデックス（0〜5）
      t.integer  :card_index,         null: false

      # 計測時点での所有者数
      t.integer  :no_of_owners,       null: false

      # 計測時点でのアクティブユーザ数
      t.integer  :no_of_active_users, null: false

      # 計測時刻
      # 同じ時刻に計測されたレコードは、この時刻がすべて同じになる
      t.datetime :reported_at,        null: false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:event_no, :book_no, :card_index, :reported_at], unique: true, name: 'index_event_ship_card_ownerships'
    end
  end
end
