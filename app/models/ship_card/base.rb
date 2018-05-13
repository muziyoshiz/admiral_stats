# ShipCard, ShipCardOwnership, EventShipCardOwnership に共通するメソッドをまとめたモジュールです。
module ShipCard::Base
  # card_index を、艦娘一覧に表示するための index（0 〜 5 の範囲）に変換して返します。
  # 艦娘一覧の表示範囲外（例：春雨限定カード）の場合は nil を返します。
  #
  # 以下のルールを上から順に適用する。
  # - book_no = 205（春雨）の場合、4番目に限定カードが入っているため、それを除外して並び替える
  # - 春雨以外の限定カードは6番目以降にあるので、除外する
  # - 表示名の末尾に改が付いている場合、改の列に表示されるように (card_index + 3) を返す
  def index_for_ship_list
    if book_no == 205
      case card_index
        when 0..2
          card_index
        when 4..6
          card_index - 1
        else
          nil
      end
    elsif card_index > 5
      nil
    elsif ship_master && ship_master.is_kai?
      card_index + 3
    else
      card_index
    end
  end

  # card_index を、カード入手率・入手数に表示するための index（0 〜 11 の範囲）に変換して返します。
  # 0〜11は、N、Nホロ、N中破、改、改ホロ、改中破、改二、改二ホロ、改二中破、改三以上、改三以上ホロ、改三以上中破を表します。
  #
  # ただし、限定カードについてはこのメソッドの対象外とします。
  # 限定カードでこのメソッドを呼び出しても、正しい値は返されません。
  def index_for_ship_card_info
    if book_no == 205
      case card_index
        when 0..2
          card_index
        when 4..6
          card_index - 1
        else
          nil
      end
    else
      case ship_master.remodel_level
        when 0
          card_index
        when 1
          # 改から始まる図鑑 No. の場合は、1枚目のカードを改と見なす
          card_index + 3
        when 2
          # 改二から始まる図鑑 No. の場合は、1枚目のカードを改二と見なす
          card_index + 6
        else
          # 改二より上のカードは、すべて「改三以上」として扱う
          card_index % 3 + 9
      end
    end
  end
end
