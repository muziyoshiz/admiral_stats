module GlobalHelper
  # 与えられた割合の値から、パーセント表記を返します。
  # nil の場合は 0 % を返します。
  def parcentage_by_rate(rate)
    rate.nil? ? '0 %' : "#{rate} %"
  end

  # 入手率の値に基づいて、CSS のクラス名を返します。
  def css_class_by_rate(rate)
    if rate.nil? or rate < 10
      'rate-tuchinoko'
    elsif rate < 30
      'rate-veryrare'
    elsif rate < 50
      'rate-rare'
    else
      'rate-common'
    end
  end

  # 攻略率をグラフ表示するための JSON を返します。
  def data_chart_cleared_rate(total_num, cleared_nums, levels)
    ret = [
        { name: '未攻略', y: total_num - cleared_nums.values.sum, color: '#AAAAAA' }
    ]

    levels.each do |level|
      ret << {
          name: "「#{difficulty_level_to_text(level)}」攻略済",
          y: cleared_nums[level],
          color: difficulty_level_to_color(level),
      }
    end

    ret.to_json
  end
end
