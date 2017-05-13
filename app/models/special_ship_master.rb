# 特別デザインのカードに関するマスタデータ
class SpecialShipMaster < ApplicationRecord
  belongs_to :ship_master, foreign_key: :book_no, primary_key: :book_no

  # 追加されたカードの図鑑 No.
  validates :book_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 350,
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
end
