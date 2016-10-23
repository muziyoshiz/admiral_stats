class CampaignMaster < ApplicationRecord
  self.primary_key = 'campaign_no'

  # 期間限定海域 No. （例：第壱回なら 1）
  validates :campaign_no,
            presence: true,
            uniqueness: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 期間限定海域名
  validates :campaign_name,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 開始時刻
  validates :started_at,
            presence: true

  # 終了時刻
  validates :ended_at,
            presence: true
end
