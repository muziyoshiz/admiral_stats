# ShipMaster と UpdatedShipMaster に共通するメソッドをまとめたモジュールです。
module ShipMaster::Base
  # 改造による名称変更を無視した、大本の名称を返します。
  # 例えば、"鈴谷改" に対して "鈴谷"、"Верный" に対して "響" を返します。
  def base_ship_name
    case ship_name
      when 'Верный'
        '響'
      when /^龍鳳/
        '大鯨'
      when /甲$/
        ship_name.sub(/甲$/, '')
      when /航$/
        ship_name.sub(/航$/, '')
      when /航改$/
        ship_name.sub(/航改$/, '')
      when /航改二$/
        ship_name.sub(/航改二$/, '')
      when /改$/
        ship_name.sub(/改$/, '')
      when /改二(甲|乙|丁)?$/
        ship_name.sub(/改二(甲|乙|丁)?$/, '')
      when / zwei$/
        ship_name.sub(/ zwei$/, '')
      when / drei$/
        ship_name.sub(/ drei$/, '')
      else
        ship_name
    end
  end

  # 図鑑 No. が同じなのに改造レベルによって艦種が変わる艦娘について、正しい艦種を返します。
  # 現在、これに該当する艦娘は、扶桑(No.26), 山城(No.27), 伊58(No.127) です。
  def ship_type_by_status(status)
    if status.book_no == 26 and status.remodel_level == 1
      '航空戦艦'
    elsif status.book_no == 27 and status.remodel_level == 1
      '航空戦艦'
    elsif status.book_no == 127 and status.remodel_level == 1
      '潜水空母'
    else
      ship_type
    end
  end

  # 艦娘のマスタデータは、以下の種類に分かれる
  # ノーマルカード3枚のみを表す
  # ノーマルカード3枚と改カード3枚を表す
  # 改カード3枚のみを表す
  # 改二カード3枚のみを表す
  #
  # このマスタデータが改/改二以上のカード3枚のみを表す場合に true を返します。
  def over_kai_only?
    # カードの名前が base_ship_name と一致しない場合、改/改二以上しかない図鑑No.のカードである
    ship_name != base_ship_name
  end

  # この図鑑No.が、改カード3枚のみを表す場合に true を返します。
  def is_kai?
    remodel_level == 1
  end
end
