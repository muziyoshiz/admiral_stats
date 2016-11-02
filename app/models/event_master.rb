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

  # このイベントの難易度の一覧を返します。
  # 難易度を返す順番は必ず HEI, OTU, KOU の順になります。
  def levels
    %w(HEI OTU KOU) & stages.map{|s| s.level }.uniq
  end
end
