class EventProgressStatus < ApplicationRecord
  # 提督 ID
  validates :admiral_id,
            presence: true,
            numericality: {
                only_integer: true,
            }

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

  # その周回で攻略済みのサブ海域番号（未攻略なら 0）
  validates :cleared_area_sub_id,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 現在の周回数（1〜）
  validates :current_loop_counts,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 最終ステージまで攻略済みの周回数（0〜）
  validates :cleared_loop_counts,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # SEGA の「提督情報」からエクスポートされた日時
  validates :exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :event_no, :level ] }
end
