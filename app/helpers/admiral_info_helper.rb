module AdmiralInfoHelper
  def event_progress_status_to_text(stages, status)
    retval = "#{status.current_loop_counts} 周目 "

    if status.current_loop_counts == status.cleared_loop_counts
      retval += "全海域突破！"
    else
      curr_stg = stages.select{|stg| stg.stage_no == status.cleared_stage_no + 1 }.first
      retval += "E-#{curr_stg.stage_no} 出撃中"
      if curr_stg.ene_military_gauge_val > 0
        retval += "（ゲージ残り #{status.current_military_gauge_left}/#{curr_stg.ene_military_gauge_val}）"
      end
    end

    retval
  end
end
