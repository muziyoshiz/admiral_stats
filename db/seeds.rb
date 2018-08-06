# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

# マスターデータの編集は、必ず Shift-JIS 形式のファイル（*_master.csv）に対して行わなければならない。
# development 環境にマスターデータを登録する際に、UTF-8 形式のファイル（*_master.utf8.csv）が生成される。
# 本番環境では新しいファイルを生成せず、この生成済みのファイルを使う。
if ENV['RAILS_ENV'] == 'development'
  Dir.glob('db/seeds/*_masters.csv') do |sjis_csv|
    utf8_csv = sjis_csv.sub(/_masters\.csv$/, '_masters.utf8.csv')
    # Excel で作った CSV ファイルを読み込むと、何故か、改行文字が CRLF になる場合と、CR のみになる場合がある
    # そのため、いずれの場合も改行文字が LF になるように変換する
    File.write(utf8_csv, File.read(sjis_csv, encoding: 'Shift_JIS:UTF-8').gsub("\r\n", "\n").gsub("\r", "\n"))
    puts "#{sjis_csv} -> #{utf8_csv}"
  end
end

CSV.read('db/seeds/ship_masters.utf8.csv', headers: true).each do |row|
  record = {
      book_no: row['Book No.'],
      ship_class: row['Ship class'],
      ship_class_index: row['Ship class index'],
      ship_type: row['Ship type'],
      ship_name: row['Ship name'],
      variation_num: row['Variation num'],
      remodel_level: (row['Remodel level'].blank? ? 0 : row['Remodel level']),
      implemented_at: (row['Implemented at'].blank? ? nil : row['Implemented at']),
  }
  ShipMaster.where(book_no: record[:book_no]).first_or_initialize.update(record)
end

CSV.read('db/seeds/updated_ship_masters.utf8.csv', headers: true).each do |row|
  record = {
      book_no: row['Book No.'],
      ship_class: row['Ship class'],
      ship_class_index: row['Ship class index'],
      ship_type: row['Ship type'],
      ship_name: row['Ship name'],
      variation_num: row['Variation num'],
      remodel_level: (row['Remodel level'].blank? ? 0 : row['Remodel level']),
      implemented_at: (row['Implemented at'].blank? ? nil : row['Implemented at']),
  }
  UpdatedShipMaster.where(book_no: record[:book_no]).first_or_initialize.update(record)
end

CSV.read('db/seeds/special_ship_masters.utf8.csv', headers: true).each do |row|
  record = {
      book_no: row['Book No.'],
      card_index: row['Card index'],
      remodel_level: (row['Remodel level'].blank? ? 0 : row['Remodel level']),
      rarity: (row['Rarity'].blank? ? 0 : row['Rarity']),
      implemented_at: (row['Implemented at'].blank? ? nil : row['Implemented at']),
  }
  SpecialShipMaster.where(book_no: record[:book_no], card_index: record[:card_index]).first_or_initialize.update(record)
end

CSV.read('db/seeds/equipment_masters.utf8.csv', headers: true).each do |data|
  record = {
      book_no: data['Book No.'],
      # Equipment ID は、production.log を "Unknown equipment:" で検索して、そのログに含まれるものを設定する
      equipment_id: (data['Equipment ID'].blank? ? nil : data['Equipment ID']),
      equipment_type: data['Equipment type'],
      equipment_name: data['Equipment name'],
      star_num: data['Rarity'].count('☆'),
      implemented_at: data['Implemented at'],
  }
  EquipmentMaster.where(book_no: record[:book_no]).first_or_initialize.update(record)
end

CSV.read('db/seeds/event_masters.utf8.csv', headers: true).each do |data|
  record = {
      event_no: data['Event No.'],
      area_id: data['Area ID'],
      event_name: data['Event name'],
      no_of_periods: data['No. of periods'],
      period1_started_at: (data['Period1 started at'].blank? ? nil : data['Period1 started at']),
      period2_started_at: (data['Period2 started at'].blank? ? nil : data['Period2 started at']),
      started_at: data['Started at'],
      ended_at: data['Ended at'],
  }
  EventMaster.where(event_no: record[:event_no]).first_or_initialize.update(record)
end

CSV.read('db/seeds/event_stage_masters.utf8.csv', headers: true).each do |data|
  record = {
      event_no: data['Event No.'],
      level: data['Level'],
      period: (data['Period'].blank? ? 0 : data['Period']),
      stage_no: data['Stage No.'],
      display_stage_no: data['Display stage No.'],
      stage_mission_name: data['Stage mission name'],
      ene_military_gauge_val: data['Ene military gauge val'],
  }
  EventStageMaster.where(event_no: record[:event_no], level: record[:level], period: record[:period], stage_no: record[:stage_no]).first_or_initialize.update(record)
end

CSV.read('db/seeds/cop_event_masters.utf8.csv', headers: true).each do |data|
  record = {
      event_no: data['Event No.'],
      area_id: data['Area ID'],
      event_name: data['Event name'],
      started_at: data['Started at'],
      ended_at: data['Ended at'],
  }
  CopEventMaster.where(event_no: record[:event_no]).first_or_initialize.update(record)
end
