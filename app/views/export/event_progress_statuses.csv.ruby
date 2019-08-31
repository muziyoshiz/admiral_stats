require 'csv'

columns = %w(exported_at event_no level period opened current_loop_counts cleared_loop_counts cleared_stage_no current_military_gauge_left)
time_columns = %w(exported_at)

CSV.generate do |csv|
  csv << columns

  @event_progress_statuses.each do |s|
    row = []
    columns.each do |col|
      if time_columns.include?(col)
        row << s.send(col.to_sym).strftime('%Y-%m-%d %H:%M:%S')
      else
        row << s.send(col.to_sym)
      end
    end
    csv << row
  end
end
