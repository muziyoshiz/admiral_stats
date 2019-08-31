require 'csv'
require 'nkf'

columns = %w(exported_at fuel ammo steel bauxite bucket level room_item_coin result_point rank title_id strategy_point kou_medal)
time_columns = %w(exported_at)
text_columns = %w(rank)

CSV.generate do |csv|
  csv << columns

  @admiral_statuses.each do |s|
    row = []
    columns.each do |col|
      if time_columns.include?(col)
        row << s.send(col.to_sym).strftime('%Y-%m-%d %H:%M:%S')
      elsif text_columns.include?(col)
        text = s.send(col.to_sym)
        if text
          row << NKF.nkf('--ic=UTF-8 --oc=CP932', text)
        else
          row << text
        end
      else
        row << s.send(col.to_sym)
      end
    end
    csv << row
  end
end
