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

    # cnt: 配列のインデックス（周回数を表す）
    # num: 各周回数に該当する提督数
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

        if cnt == cleared_loop_counts.size - 1
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

  # 輸送イベントの周回数を円グラフ表示するための JSON を返します。
  # イベント周回数と計算方法を変えている点
  # - 0周の提督も表示する（難易度が1種類しかないため）
  # - 第1回輸送イベントは、10周が1つの区切りだったため、19周目までは個別に数える
  # - 20周目以降から、「20周以上」のように10周単位でまとめる
  def data_chart_cop_cleared_loop_counts(total_num, cop_cleared_loop_counts)
    res = []

    # cnt: 配列のインデックス（周回数を表す）
    # num: 各周回数に該当する提督数
    cop_cleared_loop_counts.keys.sort.each do |cnt|
      num = cop_cleared_loop_counts[cnt]

      next if num == 0

      if cnt < 19
        res << {
            name: "#{cnt} 周",
            y: (num.to_f / total_num * 100).round(1),
        }
      elsif cnt >= 20 && cnt < 100
        # 20 以上の場合、20〜29回、などの範囲を表す
        res << {
            name: "#{cnt}〜#{cnt + 9} 周",
            y: (num.to_f / total_num * 100).round(1),
        }
      elsif cnt >= 100
        # 配列の最後は、それ以上すべての回数を表す
        res << {
            name: "#{cnt} 周以上",
            y: (num.to_f / total_num * 100).round(1),
        }
      end
    end

    p res

    res.to_json
  end

  # アクティブ提督の定義を表す数値から、その文字列表現を返します。
  def def_of_active_users_to_s(def_of_active_users)
    case def_of_active_users
      when ShipCardOwnership::DEF_ALL_ADMIRALS
        '提督全体'
      when ShipCardOwnership::DEF_ACTIVE_IN_30_DAYS
        'アクティブ提督（過去30日）'
      when ShipCardOwnership::DEF_ACTIVE_IN_60_DAYS
        'アクティブ提督（過去60日）'
      else
        '?'
    end
  end
end
