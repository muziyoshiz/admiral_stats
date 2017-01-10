module ShipInfoHelper
  # 期間を表すシンボルを、文字表現に変換します。
  def range_to_s(range)
    case range
      when :month
        '過去 1 ヶ月'
      when :three_months
        '過去 3 ヶ月'
      when :half_year
        '過去 6 ヶ月'
      when :year
        '過去 1 年'
      when :all
        '全期間'
      else
        '?'
    end
  end
end
