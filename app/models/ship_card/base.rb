# ShipCard, ShipCardOwnership, EventShipCardOwnership に共通するメソッドをまとめたモジュールです。
module ShipCard::Base
  # card_index を、艦娘一覧に表示するための index に変換して返します。
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
end
