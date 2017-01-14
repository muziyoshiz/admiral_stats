module ShipListHelper
  # 引数 status で渡された ship_status に対する改艦娘が着任している場合は true を返します。
  # status: 改艦娘がいるか調べたいレコード
  # ship_hash: book_no をキー、ShipMaster を値に持つハッシュ
  # statuses: ShipStatus の配列
  def kai_exists_for?(status, ship_hash, statuses)
    # それ自身が改以上の場合
    return false if status.remodel_level > 0

    # 艦娘名を取得できない場合
    ship = ship_hash[status.book_no]
    return false unless ship

    ship_hash.values.select{|s| s.base_ship_name == ship.ship_name }.each do |kai_ship|
      if statuses.select{|st| st.book_no == kai_ship.book_no and st.remodel_level > 0 }.present?
        # 改艦娘の ShipStatus が存在したので終了
        return true
      end
    end

    false
  end
end