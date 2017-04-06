class AdmiralToken < ApplicationRecord
  # 提督 ID
  validates :admiral_id,
            presence: true,
            numericality: {
                only_integer: true,
            }

  # 認証トークン（JWT）
  validates :token,
            presence: true,
            length: { maximum: 255 }

  # 発行時刻
  # 認証トークンに含まれる iat (issued at) と同じ時刻
  # 画面上に表示するために、専用のカラムにも保存する
  validates :issued_at,
            presence: true
end
