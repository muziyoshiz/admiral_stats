# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

CSV.read('db/ship_masters.csv', headers: true, encoding: 'Shift_JIS:UTF-8').each do |data|
  ship_master = {
      book_no: data['Book No.'],
      ship_class: data['Ship class'],
      ship_class_index: data['Ship class index'],
      ship_type: data['Ship type'],
      ship_name: data['Ship name'],
      variation_num: data['Variation num'],
      remodel_level: (data['Remodel level'].blank? ? 0 : data['Remodel level']),
      implemented_at: (data['Implemented at'].blank? ? nil : data['Implemented at']),
  }
  ShipMaster.where(book_no: ship_master[:book_no]).first_or_initialize.update(ship_master)
end

updated_ship_masters = [
    {
        book_no: 94,
        ship_class: '祥鳳型',
        ship_class_index: 1,
        ship_type: '軽空母',
        ship_name: '祥鳳',
        variation_num: 6,
        # 2017-02-07：翔鶴、瑞鶴、瑞鳳、祥鳳の「改」追加
        implemented_at: '2017-02-07T07:00:00+09:00',
    },
    {
        book_no: 106,
        ship_class: '翔鶴型',
        ship_class_index: 1,
        ship_type: '正規空母',
        ship_name: '翔鶴',
        variation_num: 6,
        # 2017-02-07：翔鶴、瑞鶴、瑞鳳、祥鳳の「改」追加
        implemented_at: '2017-02-07T07:00:00+09:00',
    },
    {
        book_no: 137,
        ship_class: '阿賀野型',
        ship_class_index: 1,
        ship_type: '軽巡洋艦',
        ship_name: '阿賀野',
        variation_num: 6,
        # 2017-08-17：4隻追加（春雨、時雨改二、阿賀野改、能代改）
        implemented_at: '2017-08-17T07:00:00+09:00',
    },
    {
        book_no: 138,
        ship_class: '阿賀野型',
        ship_class_index: 2,
        ship_type: '軽巡洋艦',
        ship_name: '能代',
        variation_num: 6,
        # 2017-08-17：4隻追加（春雨、時雨改二、阿賀野改、能代改）
        implemented_at: '2017-08-17T07:00:00+09:00',
    },
    {
        book_no: 139,
        ship_class: '阿賀野型',
        ship_class_index: 3,
        ship_type: '軽巡洋艦',
        ship_name: '矢矧',
        variation_num: 6,
        # 2017-09-21：4隻追加（香取、千歳航改二、千代田航改二、矢矧改）
        implemented_at: '2017-09-21T07:00:00+09:00',
    }
]

updated_ship_masters.each do |ship_master|
  UpdatedShipMaster.where(book_no: ship_master[:book_no]).first_or_initialize.update(ship_master)
end

special_ship_masters = [
    {
        # 日向改
        book_no: 103,
        card_index: 3,
        remodel_level: 1,
        rarity: 1,
        # 第2回イベントの前段作戦開始日
        implemented_at: '2017-04-26T07:00:00+09:00',
    },
    {
        # 伊勢改
        book_no: 102,
        card_index: 3,
        remodel_level: 1,
        rarity: 1,
        # 第2回イベントの前段作戦開始日
        implemented_at: '2017-05-11T07:00:00+09:00',
    }
]

special_ship_masters.each do |ship_master|
    SpecialShipMaster.where(book_no: ship_master[:book_no], card_index: ship_master[:card_index]).first_or_initialize.update(ship_master)
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

CSV.read('db/equipment_masters.csv', headers: true, encoding: 'Shift_JIS:UTF-8').each do |data|
  equipment_master = {
      book_no: data['Book No.'],
      equipment_id: (data['Equipment ID'].blank? ? nil : data['Equipment ID']),
      equipment_type: data['Equipment type'],
      equipment_name: data['Equipment name'],
      star_num: data['Rarity'].count('☆'),
      implemented_at: data['Implemented at'],
  }
  EquipmentMaster.where(book_no: equipment_master[:book_no]).first_or_initialize.update(equipment_master)
end
