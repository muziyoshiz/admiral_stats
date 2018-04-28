class EventShipCardOwnership < ApplicationRecord
  include ShipCard::Base

  # 艦娘のマスタデータの登録が遅れても、集計だけはできるように、optional: true を設定
  belongs_to :ship_master, foreign_key: :book_no, primary_key: :book_no, optional: true

  # イベント No. （例：第壱回なら 1）
  validates :event_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 艦娘図鑑の図鑑 No.
  validates :book_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 図鑑内のカードのインデックス（0〜6）
  validates :card_index,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 6,
            }

  # 計測時点での所有者数
  validates :no_of_owners,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
            }

  # 計測時点でのアクティブユーザ数
  validates :no_of_active_users,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
            }

  # 計測時刻
  validates :reported_at,
            presence: true,
            uniqueness: { scope: [ :event_no, :book_no, :card_index ] }
end
