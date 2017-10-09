class ShipMaster < ApplicationRecord
  include ShipMaster::Base

  self.primary_key = 'book_no'

  # 艦娘図鑑の図鑑 No.
  validates :book_no,
            presence: true,
            uniqueness: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 350,
            }

  # 艦型
  validates :ship_class,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 艦番号
  validates :ship_class_index,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 艦種
  validates :ship_type,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 艦名
  validates :ship_name,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 画像（カード）のバリエーション数
  validates :variation_num,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 6,
            }

  # ノーマルカードの改造レベルを表す数値
  # この値が 1 の場合は、図鑑の 1 枚目のカードが改
  # この値が 2 の場合は、図鑑の 1 枚目のカードが改二
  validates :remodel_level,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # Admiral Stats がサポートしている艦種のリスト
  SUPPORTED_SHIP_TYPES = %w{駆逐艦 軽巡洋艦 重雷装巡洋艦 重巡洋艦 航空巡洋艦 戦艦 航空戦艦 水上機母艦 軽空母 正規空母 練習巡洋艦}.map(&:freeze).freeze
end
