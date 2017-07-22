module ShipListHelper
  # 引数 status で渡された ship_status に対する、上位の艦娘が着任している場合は true を返します。
  # 例）ノーマルの場合は、改または改二が存在していれば true
  #
  # status: 上位の艦娘がいるか調べたいレコード
  # statuses: ShipStatus の配列
  def upper_level_exists_for?(status, statuses)
    # 艦娘名を取得できない場合は、エラー回避のために false を返す
    return false unless status.ship_master

    statuses.each do |st|
      if st.ship_master.base_ship_name == status.ship_master.base_ship_name && st.remodel_level > status.remodel_level
        return true
      end
    end

    false
  end
end