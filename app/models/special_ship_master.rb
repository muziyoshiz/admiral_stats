# 特別デザインのカードに関するマスタデータ
class SpecialShipMaster < ApplicationRecord
  belongs_to :ship_master, foreign_key: :book_no, primary_key: :book_no

  # 追加されたカードの図鑑 No.
  validates :book_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 追加されたカードの図鑑内でのインデックス（0〜）
  validates :card_index,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 5,
            },
            uniqueness: { scope: [ :book_no ] }

  # 追加されたカードの改造レベルを表す数値
  # 0 ならノーマル、1 から改
  validates :remodel_level,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 追加されたカードのレアリティを表す数値
  # 0: ノーマル相当
  # 1: ホロ相当（運が上がる）
  # 2: 中破相当（運が上がり、装甲が下がる）
  validates :rarity,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 2,
            }
end
