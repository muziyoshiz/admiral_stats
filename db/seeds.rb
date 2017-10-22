# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

CSV.read('db/seeds/ship_masters.csv', headers: true, encoding: 'Shift_JIS:UTF-8').each do |row|
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

CSV.read('db/seeds/updated_ship_masters.csv', headers: true, encoding: 'Shift_JIS:UTF-8').each do |row|
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

CSV.read('db/seeds/special_ship_masters.csv', headers: true, encoding: 'Shift_JIS:UTF-8').each do |row|
  record = {
      book_no: row['Book No.'],
      card_index: row['Card index'],
      remodel_level: (row['Remodel level'].blank? ? 0 : row['Remodel level']),
      rarity: (row['Rarity'].blank? ? 0 : row['Rarity']),
      implemented_at: (row['Implemented at'].blank? ? nil : row['Implemented at']),
  }
  SpecialShipMaster.where(book_no: record[:book_no], card_index: record[:card_index]).first_or_initialize.update(record)
end

CSV.read('db/seeds/equipment_masters.csv', headers: true, encoding: 'Shift_JIS:UTF-8').each do |data|
  record = {
      book_no: data['Book No.'],
      equipment_id: (data['Equipment ID'].blank? ? nil : data['Equipment ID']),
      equipment_type: data['Equipment type'],
      equipment_name: data['Equipment name'],
      star_num: data['Rarity'].count('☆'),
      implemented_at: data['Implemented at'],
  }
  EquipmentMaster.where(book_no: record[:book_no]).first_or_initialize.update(record)
end

event_masters = [
    {
        event_no: 1,
        area_id: 1000,
        event_name: '敵艦隊前線泊地殴り込み',
        no_of_periods: 1,
        started_at: '2016-10-27T07:00:00+09:00',
        ended_at: '2016-11-25T23:59:59+09:00',
    },
    {
        event_no: 2,
        area_id: 1001,
        event_name: '南方海域強襲偵察！',
        no_of_periods: 2,
        period1_started_at: '2017-05-11T07:00:00+09:00',
        started_at: '2017-04-26T07:00:00+09:00',
        ended_at: '2017-05-31T23:59:59+09:00',
    },
]

event_masters.each do |event_master|
  EventMaster.where(event_no: event_master[:event_no]).first_or_initialize.update(event_master)
end

event_stage_masters = [
    {
        event_no: 1,
        level: 'HEI',
        stage_no: 1,
        display_stage_no: 1,
        stage_mission_name: '前哨戦',
        ene_military_gauge_val: 1000,
    },
    {
        event_no: 1,
        level: 'HEI',
        stage_no: 2,
        display_stage_no: 2,
        stage_mission_name: '警戒線突破',
        ene_military_gauge_val: 1000,
    },
    {
        event_no: 1,
        level: 'HEI',
        stage_no: 3,
        display_stage_no: 3,
        stage_mission_name: '湾内突入！',
        ene_military_gauge_val: 1200,
    },
    {
        event_no: 1,
        level: 'HEI',
        stage_no: 4,
        display_stage_no: 4,
        stage_mission_name: '敵泊地強襲！',
        ene_military_gauge_val: 2000,
    },
    {
        event_no: 1,
        level: 'HEI',
        stage_no: 5,
        display_stage_no: 0,
        stage_mission_name: '掃討戦',
        ene_military_gauge_val: 0,
    },
    {
        event_no: 1,
        level: 'OTU',
        stage_no: 1,
        display_stage_no: 1,
        stage_mission_name: '前哨戦',
        ene_military_gauge_val: 1500,
    },
    {
        event_no: 1,
        level: 'OTU',
        stage_no: 2,
        display_stage_no: 2,
        stage_mission_name: '警戒線突破',
        ene_military_gauge_val: 1500,
    },
    {
        event_no: 1,
        level: 'OTU',
        stage_no: 3,
        display_stage_no: 3,
        stage_mission_name: '湾内突入！',
        ene_military_gauge_val: 1800,
    },
    {
        event_no: 1,
        level: 'OTU',
        stage_no: 4,
        display_stage_no: 4,
        stage_mission_name: '敵泊地強襲！',
        ene_military_gauge_val: 2500,
    },
    {
        event_no: 1,
        level: 'OTU',
        stage_no: 5,
        display_stage_no: 0,
        stage_mission_name: '掃討戦',
        ene_military_gauge_val: 0,
    },

    # 第2回イベント
    {
        event_no: 2,
        level: 'HEI',
        period: 0,
        stage_no: 1,
        display_stage_no: 1,
        stage_mission_name: '南方海域へ進出せよ！',
        ene_military_gauge_val: 2000,
    },
    {
        event_no: 2,
        level: 'HEI',
        period: 0,
        stage_no: 2,
        display_stage_no: 2,
        stage_mission_name: '警戒線を突破せよ！',
        ene_military_gauge_val: 2700,
    },
    {
        event_no: 2,
        level: 'HEI',
        period: 0,
        stage_no: 3,
        display_stage_no: 3,
        stage_mission_name: '敵洋上戦力を排除せよ！',
        ene_military_gauge_val: 2800,
    },
    {
        event_no: 2,
        level: 'HEI',
        period: 0,
        stage_no: 4,
        display_stage_no: 0,
        stage_mission_name: '敵洋上戦力を排除せよ！',
        ene_military_gauge_val: 0,
    },
    {
        event_no: 2,
        level: 'HEI',
        period: 1,
        stage_no: 1,
        display_stage_no: 4,
        stage_mission_name: '敵情偵察を開始せよ！',
        ene_military_gauge_val: 2600,
    },
    {
        event_no: 2,
        level: 'HEI',
        period: 1,
        stage_no: 2,
        display_stage_no: 5,
        stage_mission_name: '敵集結地を強襲せよ！',
        ene_military_gauge_val: 3400,
    },
    {
        event_no: 2,
        level: 'HEI',
        period: 1,
        stage_no: 3,
        display_stage_no: 6,
        stage_mission_name: '敵大型超弩級戦艦を叩け！',
        ene_military_gauge_val: 3600,
    },
    {
        event_no: 2,
        level: 'HEI',
        period: 1,
        stage_no: 4,
        display_stage_no: 0,
        stage_mission_name: '敵大型超弩級戦艦を叩け！',
        ene_military_gauge_val: 0,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 0,
        stage_no: 1,
        display_stage_no: 1,
        stage_mission_name: '南方海域へ進出せよ！',
        ene_military_gauge_val: 1800,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 0,
        stage_no: 2,
        display_stage_no: 2,
        stage_mission_name: '警戒線を突破せよ！',
        ene_military_gauge_val: 2500,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 0,
        stage_no: 3,
        display_stage_no: 3,
        stage_mission_name: '敵洋上戦力を排除せよ！',
        ene_military_gauge_val: 2600,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 0,
        stage_no: 4,
        display_stage_no: 0,
        stage_mission_name: '敵洋上戦力を排除せよ！',
        ene_military_gauge_val: 0,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 1,
        stage_no: 1,
        display_stage_no: 4,
        stage_mission_name: '敵情偵察を開始せよ！',
        ene_military_gauge_val: 2500,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 1,
        stage_no: 2,
        display_stage_no: 5,
        stage_mission_name: '敵集結地を強襲せよ！',
        ene_military_gauge_val: 3500,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 1,
        stage_no: 3,
        display_stage_no: 6,
        stage_mission_name: '敵大型超弩級戦艦を叩け！',
        ene_military_gauge_val: 3600,
    },
    {
        event_no: 2,
        level: 'OTU',
        period: 1,
        stage_no: 4,
        display_stage_no: 0,
        stage_mission_name: '敵大型超弩級戦艦を叩け！',
        ene_military_gauge_val: 0,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 0,
        stage_no: 1,
        display_stage_no: 1,
        stage_mission_name: '南方海域へ進出せよ！',
        ene_military_gauge_val: 2000,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 0,
        stage_no: 2,
        display_stage_no: 2,
        stage_mission_name: '警戒線を突破せよ！',
        ene_military_gauge_val: 2700,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 0,
        stage_no: 3,
        display_stage_no: 3,
        stage_mission_name: '敵洋上戦力を排除せよ！',
        ene_military_gauge_val: 2800,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 0,
        stage_no: 4,
        display_stage_no: 0,
        stage_mission_name: '敵洋上戦力を排除せよ！',
        ene_military_gauge_val: 0,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 1,
        stage_no: 1,
        display_stage_no: 4,
        stage_mission_name: '敵情偵察を開始せよ！',
        ene_military_gauge_val: 2700,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 1,
        stage_no: 2,
        display_stage_no: 5,
        stage_mission_name: '敵集結地を強襲せよ！',
        ene_military_gauge_val: 3700,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 1,
        stage_no: 3,
        display_stage_no: 6,
        stage_mission_name: '敵大型超弩級戦艦を叩け！',
        ene_military_gauge_val: 3800,
    },
    {
        event_no: 2,
        level: 'KOU',
        period: 1,
        stage_no: 4,
        display_stage_no: 0,
        stage_mission_name: '敵大型超弩級戦艦を叩け！',
        ene_military_gauge_val: 0,
    },
]

event_stage_masters.each do |master|
  EventStageMaster.where(event_no: master[:event_no], level: master[:level], period: master[:period], stage_no: master[:stage_no]).first_or_initialize.update(master)
end
