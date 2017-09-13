class EquipmentStatus < ApplicationRecord
  # 装備のマスタデータの登録が遅れても、インポートだけはできるように、optional: true を設定
  belongs_to :equipment_master, foreign_key: :book_no, primary_key: :book_no, optional: true

  # 提督 ID
  validates :admiral_id,
            presence: true,
            numericality: {
                only_integer: true,
            }

  # 装備図鑑の図鑑 No.
  validates :equipment_id,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 保有数
  validates :num,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # SEGA の「提督情報」からエクスポートされた日時
  validates :exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :equipment_id ] }
end
