class BlueprintStatus < ApplicationRecord
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

  # 有効期限が切れる月（有効期限が切れる月の 11日 23:59:59 の時刻が格納される）
  validates :expiration_date,
            presence: true

  # その月に有効期限が切れる改装設計図の枚数
  validates :blueprint_num,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # SEGA の「提督情報」からエクスポートされた日時
  validates :exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :book_no, :expiration_date ] }
end
