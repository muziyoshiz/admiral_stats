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
  # 第1回イベントは多段作戦ではない
  # 第2〜3回イベントは前段作戦/後段作戦
  # 第4回イベントは前段作戦/後段作戦/EO
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

  # このイベントの作戦段階のリストを返します。
  def periods
    (0..(self.no_of_periods - 1)).select{|period| stages.select{|s| s.period == period }.present? }
  end

  # このイベントの、特定の作戦番号で対応している難易度のリストを返します。
  # リストの並び順は、HEI, OTU, KOU の順にソートした状態で返します。
  #
  # この event_master の no_of_periods が 2 以上でも、event_stage_master が未登録のものは除外して返します。
  #
  # 第4回イベントの EO は OTU と KOU にしか対応していないため、HEI をスキップしてインポートするために
  # この関数が必要になりました。
  def levels_in_period(period)
    %w(HEI OTU KOU) & stages.select{|s| s.period == period }.map{|s| s.level }.uniq
  end

  # このイベントが多段作戦の場合は true を返します。
  # 多段作戦かどうかは no_of_periods の値を見て判断し、未実装なものが含まれていても「多段作戦」と判断します。
  def multi_period?
    self.no_of_periods > 1
  end
end
