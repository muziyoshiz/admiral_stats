# イベント攻略率を時系列に集計し、出力するバッチです。
# 実行方法は以下の通りです。-e オプションを指定しない場合は、development で実行されます。
# rails runner EventStatsExportBatch.execute -e (development|production)

module Enumerable
  def sum
    self.inject(:+)
  end

  def mean
    self.sum / self.length.to_f
  end

  def sample_variance
    m = self.mean
    sum = self.inject(0){|accum, i| accum + (i - m) ** 2 }
    sum / (self.length - 1).to_f
  end

  def standard_deviation
    Math.sqrt(self.sample_variance)
  end

  def percentile(percentile)
    values_sorted = self.sort
    k = (percentile * (values_sorted.length - 1) + 1).floor - 1
    f = (percentile * (values_sorted.length - 1) + 1).modulo(1)

    return values_sorted[k] + (f * (values_sorted[k + 1] - values_sorted[k]))
  end
end

class EventStatsExportBatch
  def self.execute
    # エラーチェックは省略
    event_no = ARGV[0].to_i

    event = EventMaster.find_by_event_no(event_no)
    unless event
      print "ERROR: Invalid event number '#{ARGV[0]}'\n"
      return
    end

    # TSV ヘッダの出力
    row = []
    row << '日付'
    event.periods.each do |period|
      s_period = case period
                   when 0
                     '前段作戦'
                   when 1
                     '後段作戦'
                   when 2
                     'EO'
                 end

      event.levels_in_period(period).each do |level|
        s_level = case level
                    when 'HEI'
                      '丙'
                    when 'OTU'
                      '乙'
                    when 'KOU'
                      '甲'
                  end

        row << "#{s_period} #{s_level} 提督数"
        row << "#{s_period} #{s_level} 攻略済み提督数"
        row << "#{s_period} #{s_level} 攻略率"
        row << "#{s_period} #{s_level} 攻略済み周回数（合計）"
        row << "#{s_period} #{s_level} 攻略済み周回数（平均）"
        row << "#{s_period} #{s_level} 攻略済み周回数（分散）"
        row << "#{s_period} #{s_level} 攻略済み周回数（標準偏差）"
        row << "#{s_period} #{s_level} 攻略済み周回数（中央値）"
        row << "#{s_period} #{s_level} 攻略済み周回数（95パーセンタイル）"
        row << "#{s_period} #{s_level} 攻略済み周回数（最大）"
      end
    end

    print row.join(',').encode('Shift_JIS')
    print "\n"

    # ループの開始日
    day = event.started_at.end_of_day
    # ループの終了日（イベント終了1週間後まではプレイデータをエクスポート可能）
    end_of_range = event.ended_at.end_of_day + 7.day

    while day <= end_of_range do
      # TSV 1行分のデータ
      row = []
      row << day.strftime('%Y-%m-%d')

      # 各提督の、攻略済み周回数を、作戦および難易度別に取得
      event.periods.each do |period|
        event.levels_in_period(period).each do |level|
          max_cleared_loop_counts = EventProgressStatus.find_by_sql(
              [ 'SELECT admiral_id, max(cleared_loop_counts) AS max_cleared_loop_counts ' +
                    'FROM event_progress_statuses WHERE event_no = ? AND period = ? AND level = ? AND exported_at <= ?' +
                    'GROUP BY admiral_id',
                event_no, period, level, day ]
          ).map{|s| s.max_cleared_loop_counts }

          # その作戦および難易度のプレイデータをアップロードした提督数
          admiral_num = max_cleared_loop_counts.size
          row << admiral_num

          # その作戦および難易度をクリアした提督数
          cleared_admiral_num = max_cleared_loop_counts.select{|c| c > 0 }.size
          row << cleared_admiral_num

          # その作戦および難易度をクリアした提督の割合
          row << (admiral_num == 0 ? 0 : (cleared_admiral_num.to_f / admiral_num * 100).round(1))

          # その作戦および難易度の周回数の合計値
          loop_sum = max_cleared_loop_counts.sum
          row << loop_sum

          # その作戦および難易度の周回数の平均値
          row << (admiral_num == 0 ? 0 : max_cleared_loop_counts.mean.round(1))

          # その作戦および難易度の周回数の分散
          row << (admiral_num == 0 ? 0 : max_cleared_loop_counts.sample_variance.round(2))

          # その作戦および難易度の周回数の標準偏差
          row << (admiral_num == 0 ? 0 : max_cleared_loop_counts.standard_deviation.round(2))

          # その作戦および難易度の周回数の中央値
          row << (admiral_num == 0 ? 0 : max_cleared_loop_counts.percentile(0.5).round(1))

          # その作戦および難易度の周回数の95パーセンタイル
          row << (admiral_num == 0 ? 0 : max_cleared_loop_counts.percentile(0.95).round(1))

          # その作戦および難易度の周回数の最大値
          row << max_cleared_loop_counts.max
        end
      end

      print row.join(',')
      print "\n"

      day = day + 1.day
    end
  end
end
