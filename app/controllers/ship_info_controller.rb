class ShipInfoController < ApplicationController
  before_action :authenticate

  # 残り経験値でソートする際に、便宜上の最大経験値として使う値
  MAX_EXP = 1000000

  # 艦娘別のレベル・経験値表示
  def level
    set_meta_tags title: 'レベル・経験値（艦娘別）'

    # 表示期間の指定（デフォルトは過去1ヶ月）
    if params[:range] and [:month, :three_months, :half_year, :year, :all].include?(params[:range].to_sym)
      @range = params[:range].to_sym
    else
      @range = :month
    end

    if @range == :all
      # 図鑑 No. 順に、レベルの情報を取り出す
      # remodel_level の値にかかわらず、level は同じになるはずなので、GROUP BY で重複排除する
      # TODO MySQL の ONLY_FULL_GROUP_BY 対策
      statuses = ShipStatus.where(admiral_id: current_admiral.id).
          group(:book_no, :exported_at).order(book_no: :asc, exported_at: :asc)
    else
      beginning_of_range = get_beginning_of_range_by(@range)

      # 図鑑 No. 順に、レベルの情報を取り出す
      # remodel_level の値にかかわらず、level は同じになるはずなので、GROUP BY で重複排除する
      # TODO MySQL の ONLY_FULL_GROUP_BY 対策
      statuses = ShipStatus.where(admiral_id: current_admiral.id, exported_at: beginning_of_range..Time.current).
          group(:book_no, :exported_at).order(book_no: :asc, exported_at: :asc)

      # 指定された期間にデータがなければ、範囲を全期間に変えて検索し直す
      if statuses.blank?
        @error = '指定された期間にデータが存在しなかったため、全期間のデータを表示します。'
        @range = :all
        statuses = ShipStatus.where(admiral_id: current_admiral.id).
            group(:book_no, :exported_at).order(book_no: :asc, exported_at: :asc)
      end
    end

    # 艦種を指定したい場合は、以下のクエリを実行する
    # TODO POST メソッドで以下のパラメータを渡すことで、表示する艦種を絞り込めるようにする
    # ship_type = '駆逐艦' など
=begin
    statuses = ShipStatus.where(admiral_id: current_admiral.id).
        group(:book_no, :exported_at).order(book_no: :asc, exported_at: :asc).
        joins(:ship_master).where(ship_masters: { ship_type: '駆逐艦' })
=end

    # 艦娘データがない場合
    if statuses.blank?
      render :action => 'level_blank'
      return
    end

    # 図鑑 No. とマスタデータの対応関係
    masters = {}
    ShipMaster.all.each{|m| masters[m.book_no] = m }

    # statuses から、「改」以上だけ独立した図鑑 No. になっている艦娘を除去
    # statuses の実体は ActiveRecord::relation である。そのため、to_a で配列にするまでは配列のメソッドは使えない
    statuses = statuses.to_a
    statuses.reject!{|s| masters[s.book_no].over_kai_only? }

    # キーは図鑑 No. で値は [時刻, レベル または 経験値] の配列
    levels = {}
    exps = {}
    statuses.each do |s|
      levels[s.book_no] ||= []
      levels[s.book_no] << [s.exported_at.to_i * 1000, s.level]

      exps[s.book_no] ||= []
      exps[s.book_no] << [s.exported_at.to_i * 1000, s.estimated_exp]
    end

    # キーは図鑑 No. で、値はその期間内の経験値増加量
    @increased_exps = exps.keys.each_with_object({}) do |book_no, map|
      map[book_no] = exps[book_no].last[1] - exps[book_no].first[1]
    end
    # その期間内の経験値増加量が多い上位6隻の艦娘だけ、初期状態でグラフを表示する
    visible_ships = exps.keys.sort{|book_no_1, book_no_2|
      @increased_exps[book_no_2] <=> @increased_exps[book_no_1]
    }.first(6)

    @series_level = []
    levels.keys.each do |book_no|
      @series_level << {
          'name' => "#{masters[book_no].ship_name}",
          'data' => levels[book_no],
          'visible' => visible_ships.include?(book_no),
      }
    end

    @series_exp = []
    exps.keys.each do |book_no|
      @series_exp << {
          'name' => "#{masters[book_no].ship_name}",
          'data' => exps[book_no],
          'visible' => visible_ships.include?(book_no),
      }
    end

    # 各艦娘の、指定された期間内の最初のステータスと最後のステータスを取得
    # @forecasts[図鑑No.] = {
    #   :name => 艦娘名,
    #   :begin => 最初のステータス,
    #   :end => 最後のステータス,
    #   :lv99_at => Lv 99 到達予想日時
    #   :lv99_rest => Lv 99 までの残り経験値
    # }
    @forecasts = {}

    # 最初のステータスと最後のステータスを取得
    statuses.each do |s|
      # 改/改二カードのみの図鑑エントリは除外
      next if masters[s.book_no].over_kai_only?

      # exported_at ASC でソート済みのため、その図鑑 No. で最初に登場したものが最初のステータス
      @forecasts[s.book_no] ||= { :name => masters[s.book_no].ship_name, :begin => s }
      @forecasts[s.book_no][:end] = s
    end

    # 指定された期間に、経験値が変わっていない艦娘は除外
    @forecasts.select!{|b, f| f[:begin].estimated_exp != f[:end].estimated_exp }

    # 到達予想日の計算
    @forecasts.each do |book_no, forecast|
      # 最初と最後でレベルが同じなら、傾き 0 なので予想できない
      s_begin, s_end = forecast[:begin], forecast[:end]

      # 1 秒あたりの増加経験値 = 経験値の差 / 経過時間(秒、float 型)
      exp_per_sec = (s_end.estimated_exp - s_begin.estimated_exp).to_f / (s_end.exported_at - s_begin.exported_at)

      # Lv 30 到達予想時間（Lv 30 の経験値は 43,500）
      if s_end.level < 30
        forecast[:lv30_at] = s_begin.exported_at + (43500 - s_begin.estimated_exp) / exp_per_sec
        forecast[:lv30_rest] = 43500 - s_end.estimated_exp
      end

      # Lv 50 到達予想時間（Lv 50 の経験値は 122,500）
      if s_end.level < 50
        forecast[:lv50_at] = s_begin.exported_at + (122500 - s_begin.estimated_exp) / exp_per_sec
        forecast[:lv50_rest] = 122500 - s_end.estimated_exp
      end

      # Lv 70 到達予想時間（Lv 70 の経験値は 265,000）
      if s_end.level < 70
        forecast[:lv70_at] = s_begin.exported_at + (265000 - s_begin.estimated_exp) / exp_per_sec
        forecast[:lv70_rest] = 265000 - s_end.estimated_exp
      end

      # Lv 90 到達予想時間（Lv 90 の経験値は 545,500）
      if s_end.level < 90
        forecast[:lv90_at] = s_begin.exported_at + (545500 - s_begin.estimated_exp) / exp_per_sec
        forecast[:lv90_rest] = 545000 - s_end.estimated_exp
      end

      # Lv 99 到達予想時間（Lv 99 の経験値は 1,000,000）
      if s_end.level < 99
        forecast[:lv99_at] = s_begin.exported_at + (1000000 - s_begin.estimated_exp) / exp_per_sec
        forecast[:lv99_rest] = 1000000 - s_end.estimated_exp
      end
    end

    # 到達予想日が最も近い艦娘をハイライト
    # min_by の返り値は [ book_no, forecast ] という配列になる
    soon = @forecasts.select{|b, f| f[:lv30_at] }.min_by{|b, f| f[:lv30_at] }
    soon[1][:lv30_soon] = true if soon
    soon = @forecasts.select{|b, f| f[:lv50_at] }.min_by{|b, f| f[:lv50_at] }
    soon[1][:lv50_soon] = true if soon
    soon = @forecasts.select{|b, f| f[:lv70_at] }.min_by{|b, f| f[:lv70_at] }
    soon[1][:lv70_soon] = true if soon
    soon = @forecasts.select{|b, f| f[:lv90_at] }.min_by{|b, f| f[:lv90_at] }
    soon[1][:lv90_soon] = true if soon
    soon = @forecasts.select{|b, f| f[:lv99_at] }.min_by{|b, f| f[:lv99_at] }
    soon[1][:lv99_soon] = true if soon
  end

  # 艦種別のレベル・経験値表示
  def level_summary
    set_meta_tags title: 'レベル・経験値・★5艦娘数（艦種別）'

    # 表示期間の指定（デフォルトは過去1ヶ月）
    if params[:range] and [:month, :three_months, :half_year, :year, :all].include?(params[:range].to_sym)
      @range = params[:range].to_sym
    else
      @range = :month
    end

    if @range == :all
      # 図鑑 No. 順に、レベルの情報を取り出す
      # book_no が同じでも remodel_level が違うと艦種が変わる艦娘がいる（伊勢、日向）
      # そのため、remodel_level も取得する
      statuses = ShipStatus.where(admiral_id: current_admiral.id).group(:book_no, :remodel_level, :exported_at).order(exported_at: :asc)
    else
      beginning_of_range = get_beginning_of_range_by(@range)

      # 図鑑 No. 順に、レベルの情報を取り出す
      # book_no が同じでも remodel_level が違うと艦種が変わる艦娘がいる（伊勢、日向）
      # そのため、remodel_level も取得する
      statuses = ShipStatus.where(admiral_id: current_admiral.id, exported_at: beginning_of_range..Time.current).
          group(:book_no, :remodel_level, :exported_at).order(exported_at: :asc)

      # 指定された期間にデータがなければ、範囲を全期間に変えて検索し直す
      if statuses.blank?
        @error = '指定された期間にデータが存在しなかったため、全期間のデータを表示します。'
        @range = :all
        statuses = ShipStatus.where(admiral_id: current_admiral.id).group(:book_no, :remodel_level, :exported_at).order(exported_at: :asc)
      end
    end

    # 艦娘データがない場合
    if statuses.blank?
      render :action => 'level_summary_blank'
      return
    end

    # 図鑑 No. とマスタデータの対応関係
    masters = {}
    ShipMaster.all.each{|m| masters[m.book_no] = m }

    # 艦種の並び順は、ShipMaster で定義された順とする
    # ただし、未入手の艦種は表示しない
    owned_ship_types = statuses.map{|s| masters[s.book_no].ship_type_by_status(s) }.uniq
    ship_types = ShipMaster::SUPPORTED_SHIP_TYPES.select{|t| owned_ship_types.include?(t) }

    # キーは艦種で値は [時刻, 合計レベル または 平均レベル] の配列
    levels, avg_levels = {}, {}
    # キーは艦種で値は [時刻, 合計経験値 または 平均経験値] の配列
    exps, avg_exps = {}, {}
    # キーは艦種で値は [時刻, 星5の艦娘数] の配列
    five_stars, five_stars_kai, five_stars_kai2, five_stars_kai3 = {}, {}, {}, {}
    # キーは艦種で値は [時刻, 艦娘数] の配列
    nums = {}

    ship_types.each do |ship_type|
      # 時刻ごとのレベル・経験値
      type_levels = {}
      type_exps = {}

      # 時刻ごとの加算済み艦娘名のリスト（同じ艦娘のレベルを2回加算しないためのチェックに使う）
      base_ship_names = {}

      statuses.select{|s| masters[s.book_no].ship_type_by_status(s) == ship_type }.each do |s|
        # ベースとなる艦娘名
        base_ship_name = masters[s.book_no].base_ship_name

        # その時間の、その艦娘のレベルを加算済みかどうかチェック
        base_ship_names[s.exported_at] ||= []
        next if base_ship_names[s.exported_at].include?(base_ship_name)
        base_ship_names[s.exported_at] << base_ship_name

        type_levels[s.exported_at] ||= 0
        type_levels[s.exported_at] += s.level

        type_exps[s.exported_at] ||= 0
        type_exps[s.exported_at] += s.estimated_exp
      end

      # 合計レベルおよび経験値の計算
      levels[ship_type] = type_levels.keys.map{|exported_at| [ exported_at.to_i * 1000, type_levels[exported_at] ] }
      exps[ship_type] = type_exps.keys.map{|exported_at| [ exported_at.to_i * 1000, type_exps[exported_at] ] }

      # 艦娘数の計算
      nums[ship_type] = base_ship_names.keys.map do |exported_at|
        if base_ship_names[exported_at].blank?
          [ exported_at.to_i * 1000, 0 ]
        else
          [ exported_at.to_i * 1000, base_ship_names[exported_at].size ]
        end
      end

      # 平均レベルおよび経験値の計算
      avg_levels[ship_type] = type_levels.keys.map do |exported_at|
        if base_ship_names[exported_at].blank?
          [ exported_at.to_i * 1000, 0 ]
        else
          [ exported_at.to_i * 1000, (type_levels[exported_at].to_f / base_ship_names[exported_at].size).round(2) ]
        end
      end
      avg_exps[ship_type] = type_exps.keys.map do |exported_at|
        if base_ship_names[exported_at].blank?
          [ exported_at.to_i * 1000, 0 ]
        else
          [ exported_at.to_i * 1000, (type_exps[exported_at].to_f / base_ship_names[exported_at].size).round(2) ]
        end
      end

      # 星5の艦娘数
      type_5stars = {}
      type_5stars_kai = {}
      type_5stars_kai2 = {}
      type_5stars_kai3 = {}

      statuses.select{|s| masters[s.book_no].ship_type_by_status(s) == ship_type }.each do |s|
        type_5stars[s.exported_at] ||= 0
        type_5stars_kai[s.exported_at] ||= 0
        type_5stars_kai2[s.exported_at] ||= 0
        type_5stars_kai3[s.exported_at] ||= 0
        if s.star_num == 5
          case s.remodel_level
            when 0
              type_5stars[s.exported_at] += 1
            when 1
              type_5stars_kai[s.exported_at] += 1
            when 2
              type_5stars_kai2[s.exported_at] += 1
            else
              # 改二より上のカードは、すべて「改三以上」として扱う
              type_5stars_kai3[s.exported_at] += 1
          end
        end
      end

      five_stars[ship_type] = type_5stars.keys.map{|exported_at| [ exported_at.to_i * 1000, type_5stars[exported_at] ] }
      five_stars_kai[ship_type] = type_5stars_kai.keys.map{|exported_at| [ exported_at.to_i * 1000, type_5stars_kai[exported_at] ] }
      five_stars_kai2[ship_type] = type_5stars_kai2.keys.map{|exported_at| [ exported_at.to_i * 1000, type_5stars_kai2[exported_at] ] }
      five_stars_kai3[ship_type] = type_5stars_kai3.keys.map{|exported_at| [ exported_at.to_i * 1000, type_5stars_kai3[exported_at] ] }
    end

    @series_total_level = []
    ship_types.each do |ship_type|
      @series_total_level << {
          'name' => ship_type,
          'data' => levels[ship_type],
      }
    end

    @series_total_exp = []
    ship_types.each do |ship_type|
      @series_total_exp << {
          'name' => ship_type,
          'data' => exps[ship_type],
      }
    end

    @series_average_level = []
    ship_types.each do |ship_type|
      @series_average_level << {
          'name' => ship_type,
          'data' => avg_levels[ship_type],
      }
    end

    @series_average_exp = []
    ship_types.each do |ship_type|
      @series_average_exp << {
          'name' => ship_type,
          'data' => avg_exps[ship_type],
      }
    end

    @series_5stars = []
    ship_types.each do |ship_type|
      @series_5stars << {
          'name' => ship_type,
          'data' => five_stars[ship_type],
      }
    end

    @series_5stars_kai = []
    ship_types.each do |ship_type|
      @series_5stars_kai << {
          'name' => ship_type,
          'data' => five_stars_kai[ship_type],
      }
    end

    @series_5stars_kai2 = []
    ship_types.each do |ship_type|
      @series_5stars_kai2 << {
          'name' => ship_type,
          'data' => five_stars_kai2[ship_type],
      }
    end

    @series_5stars_kai3 = []
    ship_types.each do |ship_type|
      @series_5stars_kai3 << {
          'name' => ship_type,
          'data' => five_stars_kai3[ship_type],
      }
    end

    # サマリのためのデータ取得
    @first_levels, @first_avg_levels, @first_exps, @first_avg_exps, @first_5stars, @first_5stars_kai, @first_5stars_kai2, @first_5stars_kai3, @first_nums =
        [levels, avg_levels, exps, avg_exps, five_stars, five_stars_kai, five_stars_kai2, five_stars_kai3, nums].map{|v| first_st_values(v) }
    @last_levels, @last_avg_levels, @last_exps, @last_avg_exps, @last_5stars, @last_5stars_kai, @last_5stars_kai2, @last_5stars_kai3, @last_nums =
        [levels, avg_levels, exps, avg_exps, five_stars, five_stars_kai, five_stars_kai2, five_stars_kai3, nums].map{|v| last_st_values(v) }
  end

  # カード入手数・入手率の表示
  def card
    set_meta_tags title: 'カード入手数・入手率'

    # 表示期間の指定（デフォルトは過去1ヶ月）
    if params[:range] and [:month, :three_months, :half_year, :year, :all].include?(params[:range].to_sym)
      @range = params[:range].to_sym
    else
      @range = :month
    end

    # 表示期間が「全期間」以外の場合は、その期間の開始時刻を調べる
    beginning_of_range = get_beginning_of_range_by(@range)

    if beginning_of_range
      # 指定された期間にデータがなければ、範囲を全期間に変える
      unless ShipCardTimestamp.where(['admiral_id = ? AND exported_at >= ?', current_admiral.id, beginning_of_range]).exists?
        @error = '指定された期間にデータが存在しなかったため、全期間のデータを表示します。'
        @range = :all
        beginning_of_range = nil
      end
    end

    # 入手済みのカードのデータを全入手
    ship_cards = ShipCard.where(admiral_id: current_admiral.id)

    # 艦娘図鑑データがない場合
    if ship_cards.blank?
      render :action => 'card_blank'
      return
    end

    # 実装済みの艦娘のマスタデータを全入手
    ship_masters = ShipMaster.where.not(implemented_at: nil)

    # マスタデータの更新データを全入手
    updated_ship_masters = UpdatedShipMaster.where.not(implemented_at: nil)

    # 特別カードのマスタデータを全入手
    special_ship_masters = SpecialShipMaster.where.not(implemented_at: nil)

    # どの時刻にカードが何枚増えたかを調べる
    # gains[0..8][時刻] = その時刻に増えた枚数
    # 0〜9は、N、Nホロ、N中破、改、改ホロ、改中破、改二、改二ホロ、改二中破、を表す
    # 注意：以下のように宣言すると、すべて同じオブジェクトになってしまう
    # nums = Array.new(9, {})
    gains = Array.new(9){ Hash.new }

    ship_cards.each do |card|
      # 特別カードの場合は、通常とは別の処理をする
      sp_ship_master = special_ship_masters.find{|m| m.book_no == card.book_no and m.card_index == card.card_index }
      if sp_ship_master
        case sp_ship_master.remodel_level
          when 0
            gains[sp_ship_master.rarity][card.first_exported_at] ||= 0
            gains[sp_ship_master.rarity][card.first_exported_at] += 1
          when 1
            gains[sp_ship_master.rarity + 3][card.first_exported_at] ||= 0
            gains[sp_ship_master.rarity + 3][card.first_exported_at] += 1
          when 2
            gains[sp_ship_master.rarity + 6][card.first_exported_at] ||= 0
            gains[sp_ship_master.rarity + 6][card.first_exported_at] += 1
          else
            # 改二より上のカードは現時点で未実装のため、単純に無視する
        end

        next
      end

      ship_master = ship_masters.find{|m| m.book_no == card.book_no }

      # 更新データが存在する場合は、そちらを優先する
      updated_master = updated_ship_masters.find{|m| m.book_no == card.book_no }
      ship_master = updated_master if updated_master

      # マスタデータも更新データもない場合は、未対応のデータとして無視する
      next unless ship_master

      # マスタデータに登録されている要素数を、card_index が超えている場合は、無効なデータとして無視する
      next if card.card_index >= ship_master.variation_num

      case ship_master.remodel_level
        when 0
          gains[card.card_index][card.first_exported_at] ||= 0
          gains[card.card_index][card.first_exported_at] += 1
        when 1
          # 改から始まる図鑑 No. の場合は、1枚目のカードを改と見なす
          gains[card.card_index + 3][card.first_exported_at] ||= 0
          gains[card.card_index + 3][card.first_exported_at] += 1
        when 2
          # 改二から始まる図鑑 No. の場合は、1枚目のカードを改二と見なす
          gains[card.card_index + 6][card.first_exported_at] ||= 0
          gains[card.card_index + 6][card.first_exported_at] += 1
        else
          # 改二より上のカードは現時点で未実装のため、単純に無視する
      end
    end

    # グラフに描画する時刻の一覧（時刻順にソート済）
    timestamps = ShipCardTimestamp.where(admiral_id: current_admiral.id).order(exported_at: :asc).map{|t| t.exported_at }

    # サマリを作成するために最初と最後のタイムスタンプを取得
    if beginning_of_range
      first_timestamp = timestamps.select{|t| t >= beginning_of_range }.first
    else
      # 全期間が対象の場合は beginning_of_range が nil
      first_timestamp = timestamps.first
    end
    last_timestamp = timestamps.last

    # 最終的な枚数を調べる
    # nums[0..8][時刻] = その時刻までに入手した枚数
    nums = Array.new(9){ Hash.new }

    # 時刻順に積算していく
    9.times do |idx|
      # 1つ前の時刻の値
      prev_num = 0

      timestamps.each do |timestamp|
        if gains[idx][timestamp].nil?
          # 増分がなければ、前の時刻と同じ個数をセット
          nums[idx][timestamp] = prev_num
        else
          nums[idx][timestamp] = prev_num + gains[idx][timestamp]
          prev_num = nums[idx][timestamp]
        end
      end
    end

    # タイムスタンプの最初の日付、および最後の日付の枚数を配列に記録
    @first_nums = 9.times.map{|idx| nums[idx][first_timestamp] }
    @last_nums = 9.times.map{|idx| nums[idx][last_timestamp] }

    # 実装済みの枚数を調べる
    # nums[0..8][時刻] = その時刻までに実装された枚数
    impls = Array.new(9){ Hash.new }

    # ship_masters テーブルからカード枚数の情報を生成
    released_nums = get_released_nums

    # 時刻順に取得していく
    9.times do |idx|
      timestamps.each do |timestamp|
        impls[idx][timestamp] = get_total(released_nums, idx, timestamp)
      end
    end

    # 現時点のカード総数に対する割合を計算
    # rates[0..8][時刻] = 割合
    rates = Array.new(9){ Hash.new }

    9.times do |idx|
      timestamps.each do |exported_at|
        if impls[idx][exported_at] == 0
          # 改二が未実装の期間の場合は、0 にする
          rates[idx][exported_at] = 0.0
        else
          # 整数同士で普通に割り算すると、小数点以下が無視されて 0 になる
          rates[idx][exported_at] = (100.0 * nums[idx][exported_at] / impls[idx][exported_at]).round(1)
        end
      end
    end

    # タイムスタンプの最初の日付、および最後の日付の割合を配列に記録
    @first_rates = 9.times.map{|idx| rates[idx][first_timestamp] }
    @last_rates = 9.times.map{|idx| rates[idx][last_timestamp] }

    # 全体の数および割合を計算
    total_num_data = []
    total_rate_data = []
    total_impl_data = []
    timestamps.each do |exported_at|
      # 指定された期間の結果のみプロット
      next if beginning_of_range and exported_at < beginning_of_range

      timestamp = exported_at.to_i * 1000
      num = 9.times.map{|idx| nums[idx][exported_at] }.sum
      num_impl = 9.times.map{|idx| impls[idx][exported_at] }.sum
      total_num_data << [ timestamp, num ]
      total_rate_data << [ timestamp, (100.0 * num / num_impl).round(1) ]
      total_impl_data << [ timestamp, num_impl ]
    end
    @series_num = [{ 'name' => '全体', 'data' => total_num_data }]
    @series_rate = [{ 'name' => '全体', 'data' => total_rate_data, 'tooltip' => { 'valueSuffix' => ' %' } }]
    @series_impl = [{ 'name' => '全体', 'data' => total_impl_data }]

    # サマリ表示のために、最初の日付、および最後の日付の合計値・割合を変数に保存
    # 指定された期間のデータがない場合は、何も代入しない
    if (total_num_data.present? and total_rate_data.present?)
      @first_total_num = total_num_data.first[1]
      @last_total_num = total_num_data.last[1]
      @first_total_rate = total_rate_data.first[1]
      @last_total_rate = total_rate_data.last[1]
    end

    %w(N Nホロ N中破 改 改ホロ 改中破 改二 改二ホロ 改二中破).each_with_index do |name, idx|
      num_data = []
      timestamps.each do |exported_at|
        # 指定された期間の結果のみプロット
        next if beginning_of_range and exported_at < beginning_of_range
        num_data << [exported_at.to_i * 1000, nums[idx][exported_at]]
      end

      @series_num << {
          'name' => name,
          'data' => num_data,
      }

      rate_data = []
      timestamps.each do |exported_at|
        # 指定された期間の結果のみプロット
        next if beginning_of_range and exported_at < beginning_of_range
        rate_data << [exported_at.to_i * 1000, rates[idx][exported_at]]
      end

      @series_rate << {
          'name' => name,
          'data' => rate_data,
          'tooltip' => { 'valueSuffix' => ' %' }
      }

      impl_data = []
      timestamps.each do |exported_at|
        # 指定された期間の結果のみプロット
        next if beginning_of_range and exported_at < beginning_of_range
        impl_data << [exported_at.to_i * 1000, impls[idx][exported_at]]
      end

      @series_impl << {
          'name' => name,
          'data' => impl_data,
      }
    end
  end

  private

  # 範囲を表すシンボルをもとに、その範囲の開始時刻を返します。
  def get_beginning_of_range_by(range)
    case range
      when :month
        1.month.ago
      when :three_months
        3.months.ago
      when :half_year
        6.months.ago
      when :year
        1.year.ago
      else
        # :all などの場合は nil を返す
        nil
    end
  end

  # 指定された時刻の時点での総カード枚数を、以下のような形式で返します。
=begin
    released_nums = [0..5][
        # リリース時点 2016-04-26
        [ Time.parse('2016-04-26T07:00:00+09:00'), 62 ],

        # 2016-04-28：9隻追加（長門、陸奥、白雪、初雪、深雪、磯波、涼風、霰、霞）
        [ Time.parse('2016-04-28T07:00:00+09:00'), 71 ],

        # 2016-05-26：5隻追加（雪風、睦月、如月、古鷹、加古）
        [ Time.parse('2016-05-26T07:00:00+09:00'), 76 ],

        # 2016-06-30：5隻追加（綾波、敷波、那智、足柄、羽黒）
        [ Time.parse('2016-06-30T07:00:00+09:00'), 81 ],

        # 2016-07-26：3隻追加（陽炎、不知火、黒潮）
        [ Time.parse('2016-07-26T07:00:00+09:00'), 84 ],

        # 2016-08-23：4隻追加（長良、五十鈴、名取、由良）
        [ Time.parse('2016-08-23T07:00:00+09:00'), 88 ],
    ]
=end
  def get_released_nums
    # TODO released_nums を一度生成したら Redis に一定時間キャッシュする処理を追加

    # 実装済みの艦娘のマスタデータを全入手
    ship_masters = ShipMaster.where.not(implemented_at: nil)

    # マスタデータの更新データを全入手
    updated_ship_masters = UpdatedShipMaster.where.not(implemented_at: nil)

    # 特別カードのマスタデータを全入手
    special_ship_masters = SpecialShipMaster.where.not(implemented_at: nil)

    # 艦娘追加またはマスタデータの更新が行われたタイムスタンプの抽出
    timestamps = (ship_masters.map{|m| m.implemented_at } +
        updated_ship_masters.map{|m| m.implemented_at } +
        special_ship_masters.map{|m| m.implemented_at }
    ).uniq.sort

    # card_index および時刻ごとの増加枚数を計算
    gains = Array.new(9){ Hash.new }
    # 初期値の設定
    9.times.each{|idx| timestamps.each{|t| gains[idx][t] = 0 } }

    ship_masters.each do |s|
      case s.remodel_level
        when 0
          s.variation_num.times.each{|idx| gains[idx][s.implemented_at] += 1 }
        when 1
          # 改から始まる図鑑 No. の場合は、1枚目のカードを改と見なす
          s.variation_num.times.each{|idx| gains[idx + 3][s.implemented_at] += 1 }
        when 2
          # 改二から始まる図鑑 No. の場合は、1枚目のカードを改二と見なす
          s.variation_num.times.each{|idx| gains[idx + 6][s.implemented_at] += 1 }
        else
          # 改二より上のカードは現時点で未実装のため、単純に無視する
      end
    end

    # 艦娘のマスタデータの更新は、ノーマルのみ → 改のパターンしかないはずのため、
    # それ以外のパターンは無視する
    updated_ship_masters.each do |us|
      if us.remodel_level == 0 and us.variation_num == 6
        (3..5).each{|idx| gains[idx][us.implemented_at] += 1 }
      end
    end

    # 特別カードは、改造レベルがそれぞれ別になる可能性があるため、レコード内の remodel_level を参照
    special_ship_masters.each do |ss|
      case ss.remodel_level
        when 0
          gains[ss.rarity][ss.implemented_at] += 1
        when 1
          gains[ss.rarity + 3][ss.implemented_at] += 1
        when 2
          gains[ss.rarity + 6][ss.implemented_at] += 1
        else
          # 改二より上のカードは現時点で未実装のため、単純に無視する
      end
    end

    # card_index ごとのカード総数を計算
    released_nums = Array.new(9){ Array.new }
    9.times.each do |idx|
      prev_num = 0
      timestamps.each do |implemented_at|
        num = prev_num + gains[idx][implemented_at]
        released_nums[idx] << [ implemented_at, num ]
        prev_num = num
      end
    end

    released_nums
  end

  def get_total(released_nums, card_index, exported_at)
    # リリース前の時刻を渡された場合のデフォルト値は、リリース時点のカード枚数（62）
    prev_num = 62

    released_nums[card_index].each do |released_at, num|
      return prev_num if exported_at < released_at
      prev_num = num
    end

    # いずれにも該当しなかった場合は、最新のカード枚数を返す
    prev_num
  end

  # 艦種ごとのデータから、最初のデータのみを取り出して返します。
  def first_st_values(st_values)
    st_values.map{|st, values| [st, values.first[1]] }.to_h
  end

  # 艦種ごとのデータから、最後のデータのみを取り出して返します。
  def last_st_values(st_values)
    st_values.map{|st, values| [st, values.last[1]] }.to_h
  end
end
