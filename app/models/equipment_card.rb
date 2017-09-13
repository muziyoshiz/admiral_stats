class EquipmentCard < ApplicationRecord
  # 提督 ID
  validates :admiral_id,
            presence: true,
            numericality: {
                only_integer: true,
            }

  # 装備図鑑の図鑑 No.
  validates :book_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # SEGA の「提督情報」から最初にエクスポートされた日時
  # Admiral Stats へのアップロード時に指定されたタイムスタンプのうち、最も小さいもの
  validates :first_exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :book_no ] }
end
