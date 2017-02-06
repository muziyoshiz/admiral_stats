class UpdatedShipMaster < ApplicationRecord
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

  # このマスターデータの更新の適用開始日時
  validates :implemented_at,
            presence: true
end
