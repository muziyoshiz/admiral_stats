class EventStageMaster < ApplicationRecord
  belongs_to :event, class_name: 'EventMaster', foreign_key: 'event_no'

  # イベント No. （例：第壱回なら 1）
  validates :event_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 難易度（HEI, OTU, KOU）
  validates :level,
            presence: true,
            format: { with: /\A(HEI|OTU|KOU)\z/ }

  # ステージ No. （例：E-1 なら 1）
  validates :stage_no,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            },
            uniqueness: { scope: [ :event_no, :level ] }

  # 作戦名
  validates :stage_mission_name,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 海域ゲージの最大値
  validates :ene_military_gauge_val,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }
end
