module GlobalHelper
  include EventPeriodHelper

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

  # 攻略率を円グラフ表示するための JSON を返します。
  def data_chart_cleared_rate(total_num, cleared_nums, levels)
    res = [
        { name: '未攻略', y: ((total_num - cleared_nums.values.sum).to_f / total_num * 100).round(1), color: '#AAAAAA' }
    ]

    levels.each do |level|
      res << {
          name: "「#{difficulty_level_to_text(level)}」攻略済",
          y: (cleared_nums[level].to_f / total_num * 100).round(1),
          color: difficulty_level_to_color(level),
      }
    end

    res.to_json
  end

  # 周回数を円グラフ表示するための JSON を返します。
  def data_chart_cleared_loop_counts(total_num, cleared_loop_counts)
    res = []

    # クリアした提督の総数
    total_cleared_num = total_num - cleared_loop_counts[0]

    cleared_loop_counts.each_with_index do |num, cnt|
      next if num == 0 or cnt == 0
      if cnt < 10
        res << {
            name: "#{cnt} 周",
            y: (num.to_f / total_cleared_num * 100).round(1),
        }
      elsif cnt >= 10
        # 10 以上の場合、10〜19回、などの範囲を表す
        cnt_start = ((cnt - 10) + 1) * 10
        cnt_end = ((cnt - 10) + 2) * 10 - 1

        if num == cleared_loop_counts.size - 1
          # 配列の最後は、それ以上すべての回数を表す
          res << {
              name: "#{cnt_start} 周以上",
              y: (num.to_f / total_cleared_num * 100).round(1),
          }
        else
          res << {
              name: "#{cnt_start}〜#{cnt_end} 周",
              y: (num.to_f / total_cleared_num * 100).round(1),
          }
        end
      end
    end

    res.to_json
  end

  # 周回数をヒストグラム表示するための JSON を返します。
  def series_chart_cleared_loop_counts(total_num, cleared_loop_counts, levels)
    res = []

    levels.each do |level|
      # 0〜9回はすべて表示
      counts = []
      (0..9).each do |cnt|
        counts[cnt] = cleared_loop_counts[level][cnt]
      end
      # 10回以上は1個の値にまとめる
      counts[10] = cleared_loop_counts[level][10..-1].inject{|sum, i| sum + i }

      res << {
          name: difficulty_level_to_text(level),
          data: counts.map{|cnt| (cnt.to_f / total_num * 100).round(1) },
          color: difficulty_level_to_color(level),
      }
    end

    res.to_json
  end
end
