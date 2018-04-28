class ShipCard < ApplicationRecord
  include ShipCard::Base

  # 艦娘のマスタデータの登録が遅れても、インポートだけはできるように、optional: true を設定
  belongs_to :ship_master, foreign_key: :book_no, primary_key: :book_no, optional: true

  # 提督 ID
  validates :admiral_id,
            presence: true,
            numericality: {
                only_integer: true,
            }

  # 艦娘図鑑の図鑑 No.
  validates :book_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 図鑑内のカードのインデックス（0〜5）+ スペシャルカード枠（最大6）
  validates :card_index,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 6,
            }

  # SEGA の「提督情報」から最初にエクスポートされた日時
  # Admiral Stats へのアップロード時に指定されたタイムスタンプのうち、最も小さいもの
  validates :first_exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :book_no, :card_index ] }
end
