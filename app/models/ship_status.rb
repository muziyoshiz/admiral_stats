class ShipStatus < ApplicationRecord
  belongs_to :ship_master, foreign_key: :book_no, primary_key: :book_no
  has_many :ship_slot_statuses, -> { order(slot_index: :asc) }

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
                less_than_or_equal_to: 350,
            }

  # 解像度合いを表す数値
  # （未改造の艦娘と、改造済みの艦娘が、別のデータとして返される）
  # 0: 未改造
  # 1: 改
  # 2: 改二
  validates :remodel_level,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 2,
            }

  # レベル
  validates :level,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 99,
            }

  # 星の数
  validates :star_num,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 5,
                allow_nil: true,
            }

  # 経験値の獲得割合(%)
  validates :exp_percent,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 100,
                allow_nil: true,
            }

  # 改装設計図の枚数 (From API version 7)
  validates :blueprint_total_num,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true,
            }

  # SEGA の「提督情報」からエクスポートされた日時
  validates :exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :book_no, :remodel_level ] }

  # Lv を、これまでに取得した累計経験値に変換して返します。
  # ただし、Lv および経験値の獲得割合(%)をもとに計算する都合上、多少の誤差があります。
  # この累計経験値は、艦娘の経験値テーブルが、艦これの本家と同じと仮定して計算しています。
  def estimated_exp
    CharacterListInfo.convert_lv_and_exp_percent_to_exp(self.level, self.exp_percent)
  end
end
