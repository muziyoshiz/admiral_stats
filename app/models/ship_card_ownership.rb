class ShipCardOwnership < ApplicationRecord
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

  # アクティブユーザの定義を表す整数
  # 0: 艦娘図鑑ファイルを、1回以上インポートした提督
  DEF_ALL_ADMIRALS      = 0
  # 1: 艦娘図鑑ファイルを、過去30日に1回以上インポートした提督
  DEF_ACTIVE_IN_30_DAYS = 1
  # 2: 艦娘図鑑ファイルを、過去60日に1回以上インポートした提督
  DEF_ACTIVE_IN_60_DAYS = 2
  # 選択可能な定義すべて
  DEFS_OF_ACTIVE_USERS = [ DEF_ALL_ADMIRALS, DEF_ACTIVE_IN_30_DAYS, DEF_ACTIVE_IN_60_DAYS ]
  validates :def_of_active_users,
            presence: true,
            inclusion: { in: DEFS_OF_ACTIVE_USERS }

  # 計測時刻
  validates :reported_at,
            presence: true,
            uniqueness: { scope: [ :book_no, :card_index, :def_of_active_users ] }
end
