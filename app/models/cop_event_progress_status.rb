class CopEventProgressStatus < ApplicationRecord
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

  # TPゲージの残量
  validates :numerator,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # TPゲージの最大数
  validates :denominator,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 現在の周回数（1周目＝クリア周回数0の場合は1）
  validates :achievement_number,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # "全提督協力作戦 達成報酬獲得権利" の権利獲得済かどうか
  validates :area_achievement_claim,
            inclusion: { in: [ true, false ] }

  # 限定フレームの所持数
  validates :limited_frame_num,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # SEGA の「提督情報」からエクスポートされた日時
  validates :exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :event_no ] }

  # この輸送イベント進捗情報と引数で与えられた輸送イベント進捗情報を比較して、エクスポート時刻以外の情報が同じ場合に true を返します。
  def is_comparable_with?(status)
    self.admiral_id == status.admiral_id and
        self.event_no == status.event_no and
        self.numerator == status.numerator and
        self.denominator == status.denominator and
        self.achievement_number == status.achievement_number and
        self.area_achievement_claim == status.area_achievement_claim and
        self.limited_frame_num == status.limited_frame_num
  end
end
