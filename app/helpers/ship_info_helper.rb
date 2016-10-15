module ShipInfoHelper
  # 期間を表すシンボルを、文字表現に変換します。
  def range_to_s(range)
    case range
      when :month
        '過去 1 ヶ月'
      when :all
        '全期間'
      else
        '?'
    end
  end
end
