class AdmiralStatus < ApplicationRecord
  # 提督 ID
  validates :admiral_id,
            presence: true,
            numericality: {
                only_integer: true,
            }

  # 燃料
  validates :fuel,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 弾薬
  validates :ammo,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 鋼材
  validates :steel,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # ボーキサイト
  validates :bauxite,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 修復バケツ
  validates :bucket,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 艦隊司令部Level
  validates :level,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 110,
            }

  # 家具コイン
  validates :room_item_coin,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
            }

  # 戦果 (From API version 2)
  # 戦果は数値だが、なぜか STRING 型で返される。どういう場合に文字列が返されるのかわからないが、
  # 念のため string で格納する
  # 2016-10-01 に "--" という文字列が返されるパターンがあることを発見したため、パターンの制限を廃止した。月初だけこうなる？
  validates :result_point,
            length: { minimum: 0, maximum: 32, allow_nil: true }

  # 暫定順位 (From API version 2)
  # 数値または「圏外」
  # 2016-10-01 に "--" という文字列が返されるパターンがあることを発見したため、パターンの制限を廃止した。月初だけこうなる？
  validates :rank,
            length: { minimum: 0, maximum: 32, allow_nil: true }

  # 階級を表す数値 (From API version 2)
  validates :title_id,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true,
            }

  # 戦略ポイント (From API version 2)
  validates :strategy_point,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true,
            }

  # 甲種勲章の数 (From API version 7)
  validates :kou_medal,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true,
            }

  # SEGA の「提督情報」からエクスポートされた日時
  validates :exported_at,
            presence: true,
            uniqueness: { scope: [ :admiral_id ] }

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
      # 2017-01-26: 艦隊司令部Lvの上限がLv.99からLv.110に拡張
      100 => 1300000,
      101 => 1600000,
      102 => 1900000,
      103 => 2200000,
      104 => 2600000,
      105 => 3000000,
      106 => 3500000,
      107 => 4000000,
      108 => 4600000,
      109 => 5200000,
      110 => 5900000,
  }

  # 艦隊司令部Lv.をもとに、そのLv.までに必要な累計経験値を計算して返します。
  # ただし、Lv をもとに計算する都合上、その Lv になってから取得した経験値は含みません。
  # この累計経験値は、艦隊司令部Lvの経験値テーブルが、艦これブラウザ版と同じと仮定して計算しています。
  # http://wikiwiki.jp/kancolle/?%B7%D0%B8%B3%C3%CD
  def level_to_exp
    case self.level
      when 1..50
        # Lv51までは、必要経験値が100ずつ増えていく
        self.level * (self.level - 1) * 100 / 2
      when 51..60
        # Lv61までは、次レベルまでの必要経験値が200ずつ増えていく
        a = 5000
        d = 200
        n = self.level - 50
        # Lv50 までの累計経験値 = 122500
        122500 + n * (2 * a + (n - 1) * d) / 2
      when 61..70
        # Lv71までは、次レベルまでの必要経験値が300ずつ増えていく
        a = 7000
        d = 300
        n = self.level - 60
        # Lv60 までの累計経験値 = 181500
        181500 + n * (2 * a + (n - 1) * d) / 2
      when 71..80
        # Lv81までは、次レベルまでの必要経験値が400ずつ増えていく
        a = 10000
        d = 400
        n = self.level - 70
        # Lv70 までの累計経験値 = 265000
        265000 + n * (2 * a + (n - 1) * d) / 2
      when 81..91
        # Lv91までは、次レベルまでの必要経験値が500ずつ増えていく
        a = 14000
        d = 500
        n = self.level - 80
        # Lv80 までの累計経験値 = 383000
        383000 + n * (2 * a + (n - 1) * d) / 2
      when 92..110
        # Lv92以降は規則性がなくなるため、累計経験値表から取得
        EXP_TABLE[self.level]
      else
        nil
    end
  end

  # 艦隊司令部 Lv から、最大備蓄可能各資源量を求めます。
  # http://wikiwiki.jp/kancolle-a/?%BB%F1%BA%E0 によると、計算式は 司令部Lv * 200 + 800
  def level_to_material_max
    self.level * 200 + 800
  end
end
