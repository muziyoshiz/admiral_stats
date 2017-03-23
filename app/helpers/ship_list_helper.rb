module ShipListHelper
  # 引数 status で渡された ship_status に対する、上位の艦娘が着任している場合は true を返します。
  # 例）ノーマルの場合は、改または改二が存在していれば true
  #
  # status: 上位の艦娘がいるか調べたいレコード
  # ship_hash: book_no をキー、ShipMaster を値に持つハッシュ
  # statuses: ShipStatus の配列
  def upper_level_exists_for?(status, ship_hash, statuses)
    # 艦娘名を取得できない場合は、エラー回避のために false を返す
    ship = ship_hash[status.book_no]
    return false unless ship

    ship_hash.values.select{|s| s.base_ship_name == ship.base_ship_name }.each do |kai_ship|
      if statuses.select{|st| st.book_no == kai_ship.book_no and st.remodel_level > status.remodel_level }.present?
        # 上位艦娘の ShipStatus が存在したので終了
        return true
      end
    end

    false
  end
end