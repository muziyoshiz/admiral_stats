module AdmiralInfoHelper
  # 指定されたイベントおよび作戦へのリンクを返します。
  # 多段作戦でない場合は、作戦の部分を省略します
  def link_to_period(event, period, url_options = {})
    if event.multi_period?
      link_to event_name_and_period_to_text(event, period), { event_no: event.event_no, period: period }.merge(url_options)
    else
      link_to event_name_and_period_to_text(event, period), { event_no: event.event_no }.merge(url_options)
    end
  end

  # EventMaster および period のテキスト表現を返します。
  # 多段作戦の場合は、period = 0 の場合は「(前段作戦)」、1 の場合は「(後段作戦)」を後置します。
  # 多段作戦でない場合は、イベント名のみを返します。
  def event_name_and_period_to_text(event, period)
    if event.multi_period?
      period_name = (period == 0 ? '前段作戦' : '後段作戦')
      "#{event.event_name} #{period_name}"
    else
      event.event_name
    end
  end

  # イベント進捗情報のテキスト表現を返します。
  def event_progress_status_to_text(stages, status)
    return '未開放' unless status.opened?

    retval = "#{status.current_loop_counts} 周目 "

    if status.current_loop_counts == status.cleared_loop_counts
      retval += "全海域突破！"
    else
      curr_stg = stages.select{|stg| stg.stage_no == status.cleared_stage_no + 1 }.first
      if curr_stg.display_stage_no == 0
        retval += "掃討戦 出撃中"
      else
        retval += "E-#{curr_stg.display_stage_no} 出撃中"
        if curr_stg.ene_military_gauge_val > 0
          retval += "（ゲージ残り #{status.current_military_gauge_left}/#{curr_stg.ene_military_gauge_val}）"
        end
      end
    end

    retval
  end
end
