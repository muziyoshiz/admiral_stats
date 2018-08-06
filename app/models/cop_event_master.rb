class CopEventMaster < ApplicationRecord
  self.primary_key = 'event_no'

  # イベント No. （例：第壱回なら 1）
  validates :event_no,
            presence: true,
            uniqueness: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 海域番号
  validates :area_id,
            presence: true,
            uniqueness: true,
            numericality: {
                only_integer: true,
            }

  # 期間限定海域名
  validates :event_name,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 開始時刻
  validates :started_at,
            presence: true

  # 終了時刻
  validates :ended_at,
            presence: true
end
