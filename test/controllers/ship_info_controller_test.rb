require 'test_helper'

class ShipInfoControllerTest < ActionDispatch::IntegrationTest
  test '.get_range_symbol は month, three_months, half_year, year, all に対してシンボルを返す' do
    assert_equal :month, ShipInfoController.get_range_symbol('month')
    assert_equal :three_months, ShipInfoController.get_range_symbol('three_months')
    assert_equal :half_year, ShipInfoController.get_range_symbol('half_year')
    assert_equal :year, ShipInfoController.get_range_symbol('year')
    assert_equal :all, ShipInfoController.get_range_symbol('all')
  end

  test '.get_range_symbol は無効なキーワードに対してデフォルトのシンボル :month を返す' do
    assert_equal :month, ShipInfoController.get_range_symbol('')
    assert_equal :month, ShipInfoController.get_range_symbol(nil)
    assert_equal :month, ShipInfoController.get_range_symbol('unknown')
  end

  test '.get_beginning_of_range_by は :month, :three_months, :half_year, :year に対して過去の TimeWithZone を返す' do
    t = Time.current
    assert_equal 1.month.ago(t), ShipInfoController.get_beginning_of_range_by(:month, t)
    assert_equal 3.months.ago(t), ShipInfoController.get_beginning_of_range_by(:three_months, t)
    assert_equal 6.months.ago(t), ShipInfoController.get_beginning_of_range_by(:half_year, t)
    assert_equal 1.year.ago(t), ShipInfoController.get_beginning_of_range_by(:year, t)
  end

  test '.get_beginning_of_range_by は :all やサポート外のシンボルに対して nil を返す' do
    t = Time.current
    assert_nil ShipInfoController.get_beginning_of_range_by(:all, t)
    assert_nil ShipInfoController.get_beginning_of_range_by(:unsupported, t)
    assert_nil ShipInfoController.get_beginning_of_range_by(nil, t)
  end

  test '.compute_levels_per_ship_types は、艦種ごとの合計レベルおよび平均レベルを計算して返す' do
    ship_types = %w{駆逐艦 軽巡洋艦}

    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮 Lv10 (4500, 次のLvまで残り50%だと5000)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 10,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time1)
    # 朝潮 Lv20 (19000, 次のLvまで残り50%だと20000), 大潮 Lv10 (4500), 北上 Lv10 (4500), 大井 Lv20(20000)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 20,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 1,
                               level: 20,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 86,
                               remodel_level: 0,
                               level: 10,
                               star_num: 1,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 20,
                               remodel_level: 0,
                               level: 10,
                               star_num: 1,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 19,
                               remodel_level: 0,
                               level: 20,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 86,
                              ship_class: '朝潮型',
                              ship_class_index: 2,
                              ship_type: '駆逐艦',
                              ship_name: '大潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 19,
                              ship_class: '球磨型',
                              ship_class_index: 4,
                              ship_type: '軽巡洋艦',
                              ship_name: '大井',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 20,
                              ship_class: '球磨型',
                              ship_class_index: 3,
                              ship_type: '軽巡洋艦',
                              ship_name: '北上',
                              variation_num: 3)

    levels, avg_levels = ShipInfoController.compute_levels_per_ship_types(ship_types, statuses, masters)

    # 駆逐艦の合計レベルは 10 -> 30
    assert_equal 2, levels['駆逐艦'].size
    assert_equal [time1_ms, 10], levels['駆逐艦'][0]
    assert_equal [time2_ms, 30], levels['駆逐艦'][1]
    # 駆逐艦の平均レベルは 10 -> 15
    assert_equal 2, avg_levels['駆逐艦'].size
    assert_equal [time1_ms, 10], avg_levels['駆逐艦'][0]
    assert_equal [time2_ms, 15], avg_levels['駆逐艦'][1]
    # 軽巡洋艦の合計レベルは nil -> 30
    assert_equal 1, levels['軽巡洋艦'].size
    assert_equal [time2_ms, 30], levels['軽巡洋艦'][0]
    # 軽巡洋艦の平均レベルは nil -> 15
    assert_equal 1, avg_levels['軽巡洋艦'].size
    assert_equal [time2_ms, 15], avg_levels['軽巡洋艦'][0]
  end

  test '.compute_exps_per_ship_types は、艦種ごとの合計経験値および平均経験値を計算して返す' do
    ship_types = %w{駆逐艦 軽巡洋艦}

    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮 Lv10 (4500, 次のLvまで残り50%だと5000)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 10,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time1)
    # 朝潮 Lv20 (19000, 次のLvまで残り50%だと20000), 大潮 Lv10 (4500), 北上 Lv10 (4500), 大井 Lv20(20000)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 20,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 1,
                               level: 20,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 86,
                               remodel_level: 0,
                               level: 10,
                               star_num: 1,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 20,
                               remodel_level: 0,
                               level: 10,
                               star_num: 1,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 19,
                               remodel_level: 0,
                               level: 20,
                               star_num: 1,
                               exp_percent: 50,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 86,
                              ship_class: '朝潮型',
                              ship_class_index: 2,
                              ship_type: '駆逐艦',
                              ship_name: '大潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 19,
                              ship_class: '球磨型',
                              ship_class_index: 4,
                              ship_type: '軽巡洋艦',
                              ship_name: '大井',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 20,
                              ship_class: '球磨型',
                              ship_class_index: 3,
                              ship_type: '軽巡洋艦',
                              ship_name: '北上',
                              variation_num: 3)

    exps, avg_exps = ShipInfoController.compute_exps_per_ship_types(ship_types, statuses, masters)

    # 駆逐艦の合計経験値は 5000 -> 24500
    assert_equal 2, exps['駆逐艦'].size
    assert_equal [time1_ms, 5000], exps['駆逐艦'][0]
    assert_equal [time2_ms, 24500], exps['駆逐艦'][1]
    # 駆逐艦の平均経験値は 5000 -> 12250
    assert_equal 2, avg_exps['駆逐艦'].size
    assert_equal [time1_ms, 5000], avg_exps['駆逐艦'][0]
    assert_equal [time2_ms, 12250], avg_exps['駆逐艦'][1]
    # 軽巡洋艦の合計経験値は nil -> 24500
    assert_equal 1, exps['軽巡洋艦'].size
    assert_equal [time2_ms, 24500], exps['軽巡洋艦'][0]
    # 軽巡洋艦の平均経験値は nil -> 12250
    assert_equal 1, avg_exps['軽巡洋艦'].size
    assert_equal [time2_ms, 12250], avg_exps['軽巡洋艦'][0]
  end

  test '.compute_nums_per_ship_types は、艦種ごとの艦娘数を計算して返す' do
    ship_types = %w{駆逐艦 軽巡洋艦}

    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               exported_at: time1)
    # 朝潮, 朝潮改, 大潮, 北上, 大井
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 1,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 86,
                               remodel_level: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 20,
                               remodel_level: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 19,
                               remodel_level: 0,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 86,
                              ship_class: '朝潮型',
                              ship_class_index: 2,
                              ship_type: '駆逐艦',
                              ship_name: '大潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 19,
                              ship_class: '球磨型',
                              ship_class_index: 4,
                              ship_type: '軽巡洋艦',
                              ship_name: '大井',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 20,
                              ship_class: '球磨型',
                              ship_class_index: 3,
                              ship_type: '軽巡洋艦',
                              ship_name: '北上',
                              variation_num: 3)

    nums = ShipInfoController.compute_nums_per_ship_types(ship_types, statuses, masters)

    # 駆逐艦の合計は 1 -> 2
    assert_equal 2, nums['駆逐艦'].size
    assert_equal [time1_ms, 1], nums['駆逐艦'][0]
    assert_equal [time2_ms, 2], nums['駆逐艦'][1]
    # 軽巡洋艦の合計は nil -> 2
    assert_equal 1, nums['軽巡洋艦'].size
    assert_equal [time2_ms, 2], nums['軽巡洋艦'][0]
  end

  test '.compute_stars_per_ship_types は、艦種ごとの星5艦娘数を計算して返す' do
    ship_types = %w{駆逐艦 水上機母艦 軽空母}

    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮(1), 千歳(5), 千歳改(1), 千歳甲(5), 千歳航(1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               star_num: 1,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 49,
                               remodel_level: 0,
                               star_num: 5,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 95,
                               remodel_level: 1,
                               star_num: 1,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 99,
                               remodel_level: 2,
                               star_num: 5,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               star_num: 1,
                               exported_at: time1)
    # 朝潮(1), 千歳(5), 千歳改(5), 千歳甲(5), 千歳航(5), 千歳航改(5)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               star_num: 1,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 49,
                               remodel_level: 0,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 95,
                               remodel_level: 1,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 99,
                               remodel_level: 2,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 4,
                               star_num: 5,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 49,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 95,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳改',
                              variation_num: 3,
                              remodel_level: 1)
    masters << ShipMaster.new(book_no: 99,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳甲',
                              variation_num: 3,
                              remodel_level: 2)
    masters << ShipMaster.new(book_no: 104,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '軽空母',
                              ship_name: '千歳航',
                              variation_num: 6,
                              remodel_level: 3)

    stars, kai_stars, kai2_stars, kai3_stars = ShipInfoController.compute_stars_per_ship_types(ship_types, statuses, masters)

    # 駆逐艦ノーマル の合計は 0 -> 0
    assert_equal 2, stars['駆逐艦'].size
    assert_equal [time1_ms, 0], stars['駆逐艦'][0]
    assert_equal [time2_ms, 0], stars['駆逐艦'][1]
    # 駆逐艦改 の合計は 0 -> 0
    assert_equal 2, kai_stars['駆逐艦'].size
    assert_equal [time1_ms, 0], kai_stars['駆逐艦'][0]
    assert_equal [time2_ms, 0], kai_stars['駆逐艦'][1]
    # 駆逐艦改二 の合計は 0 -> 0
    assert_equal 2, kai2_stars['駆逐艦'].size
    assert_equal [time1_ms, 0], kai2_stars['駆逐艦'][0]
    assert_equal [time2_ms, 0], kai2_stars['駆逐艦'][1]
    # 駆逐艦改三以上 の合計は 0 -> 0
    assert_equal 2, kai3_stars['駆逐艦'].size
    assert_equal [time1_ms, 0], kai3_stars['駆逐艦'][0]
    assert_equal [time2_ms, 0], kai3_stars['駆逐艦'][1]

    # 水上機母艦ノーマル の合計は 1 -> 1
    assert_equal 2, stars['水上機母艦'].size
    assert_equal [time1_ms, 1], stars['水上機母艦'][0]
    assert_equal [time2_ms, 1], stars['水上機母艦'][1]
    # 水上機母艦改 の合計は 0 -> 1
    assert_equal 2, kai_stars['水上機母艦'].size
    assert_equal [time1_ms, 0], kai_stars['水上機母艦'][0]
    assert_equal [time2_ms, 1], kai_stars['水上機母艦'][1]
    # 水上機母艦改二 の合計は 1 -> 1
    assert_equal 2, kai2_stars['水上機母艦'].size
    assert_equal [time1_ms, 1], kai2_stars['水上機母艦'][0]
    assert_equal [time2_ms, 1], kai2_stars['水上機母艦'][1]
    # 水上機母艦改三以上 の合計は 0 -> 0
    assert_equal 2, kai3_stars['水上機母艦'].size
    assert_equal [time1_ms, 0], kai3_stars['水上機母艦'][0]
    assert_equal [time2_ms, 0], kai3_stars['水上機母艦'][1]

    # 軽空母ノーマル の合計は 0 -> 0
    assert_equal 2, stars['軽空母'].size
    assert_equal [time1_ms, 0], stars['軽空母'][0]
    assert_equal [time2_ms, 0], stars['軽空母'][1]
    # 軽空母改 の合計は 0 -> 0
    assert_equal 2, kai_stars['軽空母'].size
    assert_equal [time1_ms, 0], kai_stars['軽空母'][0]
    assert_equal [time2_ms, 0], kai_stars['軽空母'][1]
    # 軽空母改二 の合計は 0 -> 0
    assert_equal 2, kai2_stars['軽空母'].size
    assert_equal [time1_ms, 0], kai2_stars['軽空母'][0]
    assert_equal [time2_ms, 0], kai2_stars['軽空母'][1]
    # 軽空母改三以上 の合計は 0 -> 2
    assert_equal 2, kai3_stars['軽空母'].size
    assert_equal [time1_ms, 0], kai3_stars['軽空母'][0]
    assert_equal [time2_ms, 2], kai3_stars['軽空母'][1]
  end

  test '.compute_grand_levels は、全艦隊の合計レベルおよび平均レベルを計算して返す' do
    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮, 千歳航
    # 朝潮は Lv 10, 残り 50% (5000)
    # 千歳は Lv 10, 残り 0% (4500)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 10,
                               exp_percent: 50,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               level: 10,
                               exp_percent: 0,
                               exported_at: time1)
    # 朝潮, 朝潮改, 千歳, 千歳改, 千歳甲, 千歳航, 千歳航改
    # 朝潮は Lv 20, 残り 50% (20000)
    # 千歳は Lv 20, 残り 0% (19000)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 20,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 1,
                               level: 20,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 49,
                               remodel_level: 0,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 95,
                               remodel_level: 1,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 99,
                               remodel_level: 2,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 4,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 49,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 95,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳改',
                              variation_num: 3,
                              remodel_level: 1)
    masters << ShipMaster.new(book_no: 99,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳甲',
                              variation_num: 3,
                              remodel_level: 2)
    masters << ShipMaster.new(book_no: 104,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '軽空母',
                              ship_name: '千歳航',
                              variation_num: 6,
                              remodel_level: 3)

    grand_levels, grand_avg_levels = ShipInfoController.compute_grand_levels(statuses, masters)

    # 合計レベルは 20 -> 40
    assert_equal 2, grand_levels.size
    assert_equal [time1_ms, 20], grand_levels[0]
    assert_equal [time2_ms, 40], grand_levels[1]
    # 平均レベルは 10 -> 20
    assert_equal 2, grand_avg_levels.size
    assert_equal [time1_ms, 10], grand_avg_levels[0]
    assert_equal [time2_ms, 20], grand_avg_levels[1]
  end

  test '.compute_grand_exps は、全艦隊の合計経験値および平均経験値を計算して返す' do
    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮, 千歳航
    # 朝潮は Lv 10, 残り 50% (5000)
    # 千歳は Lv 10, 残り 0% (4500)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 10,
                               exp_percent: 50,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               level: 10,
                               exp_percent: 0,
                               exported_at: time1)
    # 朝潮, 朝潮改, 千歳, 千歳改, 千歳甲, 千歳航, 千歳航改
    # 朝潮は Lv 20, 残り 50% (20000)
    # 千歳は Lv 20, 残り 0% (19000)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               level: 20,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 1,
                               level: 20,
                               exp_percent: 50,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 49,
                               remodel_level: 0,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 95,
                               remodel_level: 1,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 99,
                               remodel_level: 2,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 4,
                               level: 20,
                               exp_percent: 0,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 49,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 95,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳改',
                              variation_num: 3,
                              remodel_level: 1)
    masters << ShipMaster.new(book_no: 99,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳甲',
                              variation_num: 3,
                              remodel_level: 2)
    masters << ShipMaster.new(book_no: 104,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '軽空母',
                              ship_name: '千歳航',
                              variation_num: 6,
                              remodel_level: 3)

    grand_exps, grand_avg_exps = ShipInfoController.compute_grand_exps(statuses, masters)

    # 合計経験値は 9500 -> 39000
    assert_equal 2, grand_exps.size
    assert_equal [time1_ms, 9500], grand_exps[0]
    assert_equal [time2_ms, 39000], grand_exps[1]
    # 平均経験値は 4750 -> 19500
    assert_equal 2, grand_avg_exps.size
    assert_equal [time1_ms, 4750], grand_avg_exps[0]
    assert_equal [time2_ms, 19500], grand_avg_exps[1]
  end

  test '.compute_grand_nums は、全艦隊の艦娘数を計算して返す' do
    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮, 千歳航
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               exported_at: time1)
    # 朝潮, 朝潮改, 大潮, 千歳, 千歳改, 千歳甲, 千歳航, 千歳航改
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 1,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 86,
                               remodel_level: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 49,
                               remodel_level: 0,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 95,
                               remodel_level: 1,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 99,
                               remodel_level: 2,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 4,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 86,
                              ship_class: '朝潮型',
                              ship_class_index: 2,
                              ship_type: '駆逐艦',
                              ship_name: '大潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 49,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 95,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳改',
                              variation_num: 3,
                              remodel_level: 1)
    masters << ShipMaster.new(book_no: 99,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳甲',
                              variation_num: 3,
                              remodel_level: 2)
    masters << ShipMaster.new(book_no: 104,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '軽空母',
                              ship_name: '千歳航',
                              variation_num: 6,
                              remodel_level: 3)

    grand_nums = ShipInfoController.compute_grand_nums(statuses, masters)

    # 艦娘数は 2 -> 3
    assert_equal 2, grand_nums.size
    assert_equal [time1_ms, 2], grand_nums[0]
    assert_equal [time2_ms, 3], grand_nums[1]
  end

  test '.compute_grand_stars は、全艦隊の星5艦娘数を計算して返す' do
    ship_types = %w{駆逐艦 水上機母艦 軽空母}

    time1 = Time.parse('2017-07-01 16:00:00 +09:00')
    time1_ms = time1.to_i * 1000
    time2 = Time.parse('2017-07-02 16:00:00 +09:00')
    time2_ms = time2.to_i * 1000

    statuses = []
    # 朝潮(1), 千歳(5), 千歳改(1), 千歳甲(5), 千歳航(1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               star_num: 1,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 49,
                               remodel_level: 0,
                               star_num: 5,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 95,
                               remodel_level: 1,
                               star_num: 1,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 99,
                               remodel_level: 2,
                               star_num: 5,
                               exported_at: time1)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               star_num: 1,
                               exported_at: time1)
    # 朝潮(1), 千歳(5), 千歳改(5), 千歳甲(5), 千歳航(5), 千歳航改(5)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 85,
                               remodel_level: 0,
                               star_num: 1,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 49,
                               remodel_level: 0,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 95,
                               remodel_level: 1,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 99,
                               remodel_level: 2,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 3,
                               star_num: 5,
                               exported_at: time2)
    statuses << ShipStatus.new(admiral_id: 1,
                               book_no: 104,
                               remodel_level: 4,
                               star_num: 5,
                               exported_at: time2)

    masters = []
    masters << ShipMaster.new(book_no: 85,
                              ship_class: '朝潮型',
                              ship_class_index: 1,
                              ship_type: '駆逐艦',
                              ship_name: '朝潮',
                              variation_num: 6)
    masters << ShipMaster.new(book_no: 49,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳',
                              variation_num: 3)
    masters << ShipMaster.new(book_no: 95,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳改',
                              variation_num: 3,
                              remodel_level: 1)
    masters << ShipMaster.new(book_no: 99,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '水上機母艦',
                              ship_name: '千歳甲',
                              variation_num: 3,
                              remodel_level: 2)
    masters << ShipMaster.new(book_no: 104,
                              ship_class: '千歳型',
                              ship_class_index: 1,
                              ship_type: '軽空母',
                              ship_name: '千歳航',
                              variation_num: 6,
                              remodel_level: 3)

    stars, kai_stars, kai2_stars, kai3_stars = ShipInfoController.compute_grand_stars(statuses)

    # ノーマル の合計は 1 -> 1
    assert_equal 2, stars.size
    assert_equal [time1_ms, 1], stars[0]
    assert_equal [time2_ms, 1], stars[1]
    # 改 の合計は 0 -> 1
    assert_equal 2, kai_stars.size
    assert_equal [time1_ms, 0], kai_stars[0]
    assert_equal [time2_ms, 1], kai_stars[1]
    # 改二 の合計は 1 -> 1
    assert_equal 2, kai2_stars.size
    assert_equal [time1_ms, 1], kai2_stars[0]
    assert_equal [time2_ms, 1], kai2_stars[1]
    # 改三以上 の合計は 0 -> 2
    assert_equal 2, kai3_stars.size
    assert_equal [time1_ms, 0], kai3_stars[0]
    assert_equal [time2_ms, 2], kai3_stars[1]
  end
end
