require 'csv'

columns = %w(exported_at event_no numerator denominator achievement_number area_achievement_claim limited_frame_num)
time_columns = %w(exported_at)

CSV.generate do |csv|
  csv << columns

  @cop_event_progress_statuses.each do |s|
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
