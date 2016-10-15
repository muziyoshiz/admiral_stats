class ShipStatus < ApplicationRecord
  belongs_to :ship_master, foreign_key: :book_no, primary_key: :book_no

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
  validates :remodel_level,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 1,
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

  # SEGA の「提督情報」からエクスポートされた日時
  validates :exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id, :book_no, :remodel_level ] }

  # 累計経験値表
  EXP_TABLE = {
      92 => 584500,
      93 => 606500,
      94 => 631500,
      95 => 661500,
      96 => 701500,
      97 => 761500,
      98 => 851500,
      99 => 1000000,
  }

  # Lv を、これまでに取得した累計経験値に変換して返します。
  # ただし、Lv をもとに計算する都合上、その Lv になってから取得した経験値は含みません。
  # この累計経験値は、艦娘の経験値テーブルが、艦これの本家と同じと仮定して計算しています。
  def level_to_exp
    ShipStatus.exp_for(self.level)
  end

  # 与えられた Lv になるために必要な累計経験値を返します。
  # この累計経験値は、艦娘の経験値テーブルが、艦これの本家と同じと仮定して計算しています。
  def self.exp_for(level)
    case level
      when 1..50
        # Lv51までは、必要経験値が100ずつ増えていく
        level * (level - 1) * 100 / 2
      when 51..60
        # Lv61までは、次レベルまでの必要経験値が200ずつ増えていく
        a = 5000
        d = 200
        n = level - 50
        # Lv50 までの累計経験値 = 122500
        122500 + n * (2 * a + (n - 1) * d) / 2
      when 61..70
        # Lv71までは、次レベルまでの必要経験値が300ずつ増えていく
        a = 7000
        d = 300
        n = level - 60
        # Lv60 までの累計経験値 = 181500
        181500 + n * (2 * a + (n - 1) * d) / 2
      when 71..80
        # Lv81までは、次レベルまでの必要経験値が400ずつ増えていく
        a = 10000
        d = 400
        n = level - 70
        # Lv70 までの累計経験値 = 265000
        265000 + n * (2 * a + (n - 1) * d) / 2
      when 81..91
        # Lv91までは、次レベルまでの必要経験値が500ずつ増えていく
        a = 14000
        d = 500
        n = level - 80
        # Lv80 までの累計経験値 = 383000
        383000 + n * (2 * a + (n - 1) * d) / 2
      when 92..99
        # Lv92以降は規則性がなくなるため、累計経験値表から取得
        EXP_TABLE[level]
      else
        nil
    end
  end
end
