class EventMaster < ApplicationRecord
  has_many :stages, -> { order(:stage_no) }, class_name: 'EventStageMaster', foreign_key: 'event_no'

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

  # 作戦数（通常は1、多段作戦の場合は2以上）
  # 第1回イベントは多段作戦ではない。第2回イベントは前段作戦/後段作戦
  validates :no_of_periods,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
            }

  # 開始時刻
  validates :started_at,
            presence: true

  # 終了時刻
  validates :ended_at,
            presence: true

  # このイベントの難易度の一覧を返します。
  # 難易度を返す順番は必ず HEI, OTU, KOU の順になります。
  def levels
    %w(HEI OTU KOU) & stages.map{|s| s.level }.uniq
  end

  # このイベントの作戦番号（0〜）のリストを返します。
  # この event_master の no_of_periods が 2 以上でも、event_stage_master が未登録のものは除外して返します。
  def periods
    (0..(no_of_periods - 1)).select{|period| stages.select{|s| s.period == period}.present? }
  end
end
