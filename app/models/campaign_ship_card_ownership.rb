class CampaignShipCardOwnership < ApplicationRecord
  # 期間限定海域 No. （例：第壱回なら 1）
  validates :campaign_no,
            presence: true,
            uniqueness: true,
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
                less_than_or_equal_to: 350,
            }

  # 図鑑内のカードのインデックス（0〜5）
  validates :card_index,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 5,
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
            uniqueness: { scope: [ :campaign_no, :book_no, :card_index ] }
end
