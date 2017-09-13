class EquipmentMaster < ApplicationRecord
  self.primary_key = 'book_no'

  # 装備図鑑の図鑑 No.
  validates :book_no,
            presence: true,
            uniqueness: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 装備一覧の装備 ID
  # 図鑑 No. と異なる場合があるので、事前にわからない。未知の装備の場合は NULL
  # uniqueness: true にすると、equipment_id が NULL のレコードを1件しか作れなかった
  validates :equipment_id,
            numericality: {
                allow_nil: true,
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 装備種別
  # SEGA 公式サイトから返される値よりも、装備種別を細かく表したもの
  validates :equipment_type,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 装備名
  validates :equipment_name,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 装備のレアリティを表す星の数
  validates :star_num,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 6,
            }
end
