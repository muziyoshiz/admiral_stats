class ShipSlotStatus < ApplicationRecord
  belongs_to :ship_status

  # このデータが紐付けられた ship_status の ID
  validates :ship_status_id,
            presence: true,
            numericality: {
                only_integer: true,
            }

  # スロットの位置を表すインデックス（0〜3）
  validates :slot_index,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 3,
            },
            uniqueness: { scope: [ :ship_status_id ] }

  # 装備名
  # 未装備の場合は空文字列
  validates :slot_equip_name,
            length: { minimum: 0, maximum: 32 }

  # 搭載可能な艦載機数
  validates :slot_amount,
            presence: true,
            numericality: {
                only_integer: true,
            }

  # 搭載状況を表す文字列を、数値に変換したもの
  # 0: 'NONE'
  # 1: 'NOT_EQUIPPED_AIRCRAFT'
  # 2: 'EQUIPPED_AIRCRAFT'
  validates :slot_disp,
            presence: true,
            numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                less_than_or_equal_to: 2,
            }

  # JSON に含まれる slot_disp の値を、対応する数値に変換して返します。
  def self.convert_slot_disp_to_i(slot_disp)
    case slot_disp
      when 'NONE'
        0
      when 'NOT_EQUIPPED_AIRCRAFT'
        1
      when 'EQUIPPED_AIRCRAFT'
        2
      else
        raise "Unsupported slot_disp: #{slot_disp}"
    end
  end
end
