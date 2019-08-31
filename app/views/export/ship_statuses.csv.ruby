require 'csv'

columns = %w(exported_at book_no remodel_level level star_num exp_percent blueprint_total_num married)
time_columns = %w(exported_at)

CSV.generate do |csv|
  csv << columns

  @ship_statuses.each do |s|
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
