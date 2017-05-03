class AdmiralInfoController < ApplicationController
  before_action :authenticate

  # title ヘッダを生成するために読み込み
  include AdmiralInfoHelper

  # 暫定順位が「圏外」だった場合に、仮に表示する数値
  # @sophiarcp さんの検証結果によると、3000 位近辺がボーダーと思われる
  RANK_KENGAI = 3100

  # 提督の基本情報を表示します。
  def index
    set_meta_tags title: '提督情報'

    # 表示期間の指定（デフォルトは過去1ヶ月）
    if params[:range] and [:month, :three_months, :half_year, :year, :all].include?(params[:range].to_sym)
      @range = params[:range].to_sym
    else
      @range = :month
    end

    if @range == :all
      # 提督情報を一括取得
      admiral_statuses = AdmiralStatus.where(admiral_id: current_admiral.id).order(exported_at: :asc)
    else
      beginning_of_range = get_beginning_of_range_by(@range)

      # 過去1ヶ月分の提督情報を一括取得
      admiral_statuses = AdmiralStatus.where(admiral_id: current_admiral.id, exported_at: beginning_of_range..Time.current).
          order(exported_at: :asc)

      # 指定された期間にデータがなければ、範囲を全期間に変えて検索し直す
      if admiral_statuses.blank?
        @error = '指定された期間にデータが存在しなかったため、全期間のデータを表示します。'
        @range = :all
        admiral_statuses = AdmiralStatus.where(admiral_id: current_admiral.id).order(exported_at: :asc)
      end
    end

    # 提督情報がなければ、処理を終了
    if admiral_statuses.blank?
      render :action => 'index_blank'
      return
    end

    # 指定された期間で最も古いステータスと、最新のステータス（最大備蓄可能各資源量などを、ここから取得）
    @first_status = admiral_statuses.first
    @last_status = admiral_statuses.last

    # 提督の Lv および経験値
    data_level, data_exp = [], []
    admiral_statuses.each do |status|
      timestamp_js = status.exported_at.to_i  * 1000
      data_level << [ timestamp_js, status.level ]
      data_exp << [ timestamp_js, status.level_to_exp ]
    end

    @series_level_exp = [
        { 'name' => 'レベル', 'data' => data_level },
        { 'name' => '経験値', 'data' => data_exp, 'yAxis' => 1 },
    ]

    # 資源の消費量
    data_fuel, data_ammo, data_steel, data_bauxite = [], [], [], []
    admiral_statuses.each do |status|
      timestamp_js = status.exported_at.to_i  * 1000
      data_fuel << [ timestamp_js, status.fuel ]
      data_ammo << [ timestamp_js, status.ammo ]
      data_steel << [ timestamp_js, status.steel ]
      data_bauxite << [ timestamp_js, status.bauxite ]
    end

    @series_material = [
        { 'name' => '燃料', 'data' => data_fuel },
        { 'name' => '弾薬', 'data' => data_ammo },
        { 'name' => '鋼材', 'data' => data_steel },
        { 'name' => 'ボーキサイト', 'data' => data_bauxite },
    ]

    # 資源以外の消耗品
    data_bucket, data_room_item_coin, data_strategy_point = [], [], []
    admiral_statuses.each do |status|
      timestamp_js = status.exported_at.to_i  * 1000
      data_bucket << [ timestamp_js, status.bucket ]
      data_room_item_coin << [ timestamp_js, status.room_item_coin ]
      # 戦略ポイントは REVISION 2 からの実装なので、nil の場合がある
      data_strategy_point << [ timestamp_js, status.strategy_point ] if status.strategy_point
    end

    @series_consumable = [
        { 'name' => '修復バケツ', 'data' => data_bucket, 'yAxis' => 0 },
        { 'name' => '家具コイン', 'data' => data_room_item_coin, 'yAxis' => 1 },
        { 'name' => '戦略ポイント', 'data' => data_strategy_point, 'yAxis' => 2, 'tooltip' => { 'valueSuffix' => ' pt' } },
    ]

    # 戦果
    data_result_point =  []
    admiral_statuses.each do |status|
      timestamp_js = status.exported_at.to_i  * 1000

      # 戦果は REVISION 2 からの実装なので、nil の場合がある
      # 戦果は数値だが、なぜか STRING 型で返される
      # 中身が数値か確認し、数値だった場合のみ、チャートにプロットする
      if status.result_point and status.result_point =~ /^\d+$/
        data_result_point << [ timestamp_js, status.result_point.to_i ]
      end
    end

    @series_result_point = [
        { 'name' => '戦果', 'data' => data_result_point }
    ]

    # 暫定順位（1位をグラフの一番上に表示し、圏外をX軸の位置に表示する）
    data_rank = []
    admiral_statuses.each do |status|
      timestamp_js = status.exported_at.to_i  * 1000

      # 暫定順位は REVISION 2 からの実装なので、nil の場合がある
      if status.rank
        # 暫定順位は '圏外' または 数値 で返される
        # 中身が数値の場合はその数値をプロットし、それ以外の場合は仮の固定値を代入
        if status.rank =~ /^\d+$/
          data_rank << [ timestamp_js, status.rank.to_i ]
        elsif status.rank == '圏外'
          data_rank << [ timestamp_js, RANK_KENGAI ]
        else
          # 暫定順位が "--" の場合は、月初で値を取得できていないだけ、と考えて、グラフにプロットしない
        end
      end
    end

    @series_rank = [
        { 'name' => '暫定順位', 'data' => data_rank }
    ]
    # 表示された暫定順位の最大値が「圏外」の場合は、その値を下限に設定する
    # それ以外の場合は Highcharts の自動調整に任せる
    @rank_max = (data_rank.map{|r| r[1] }.max == RANK_KENGAI) ? RANK_KENGAI : nil
  end

  # イベント進捗情報のサマリを表示します。
  def event
    # すでに開始しているイベントを全取得
    @events = EventMaster.where('started_at <= ?', Time.current).to_a
    if @events.size == 0
      redirect_to root_url
      return
    end

    # URLパラメータでイベント No. を指定されたらそれを表示し、指定されなければ最新のイベントを表示
    if params[:event_no]
      @event = @events.select{|e| e.event_no == params[:event_no].to_i }.first
      unless @event
        redirect_to root_url
        return
      end
    else
      @event = @events.max{|e| e.event_no }
    end

    # URLパラメータで作戦を指定されたらそれを表示し、指定されなければ最新の作戦を表示
    if params[:period]
      # 存在しない、または未実装の作戦が指定された場合は、ホーム画面にリダイレクトする
      @period = params[:period].to_i
      unless @event.periods.include?(@period)
        redirect_to root_url
        return
      end
    else
      # period が指定されなかった場合は、実装済みの最新の作戦
      # 前段作戦、後段作戦に分かれていない場合は 0 を返す
      @period = @event.periods.last
    end

    # 作戦の開始日を取得（後段作戦の場合は、後段作戦の開始日）
    # 前提1：後段作戦が開始しても、前段作戦をプレイできる
    # 前提2：前段作戦と後段作戦の終了日は同じである
    @started_at = (@period == 1 ? @event.period1_started_at : @event.started_at)

    set_meta_tags title: "イベントの進捗（#{event_name_and_period_to_text(@event, @period)}）"

    all_statuses = EventProgressStatus.where(admiral_id: current_admiral.id, event_no: @event.event_no, period: @period).to_a

    # イベント進捗情報がなければ、処理を終了
    if all_statuses.blank?
      if EventProgressStatus.exists?(admiral_id: current_admiral.id)
        # 他のイベントはアップロード済みなら、他のイベントへのリンクを表示する
        render :action => 'event_blank'
      else
        # どのイベントの結果もアップロードされていないなら、説明を表示する
        render :action => 'event_guide'
      end
      return
    end

    # イベント履歴の重複を排除した結果を @statuses に格納する
    # 同じ意味のイベント進捗が複数ある場合は、一番エクスポート時刻が古いものだけ残す
    @statuses = []

    @event.levels.each do |level|
      prev_status = nil

      # 特定の難易度のイベント進捗情報を、エクスポート時刻が古い順に取得
      all_statuses.select{|s| s.level == level }.sort_by{|s| s.exported_at }.each do |s|
        # すでに同じ内容のイベント進捗情報がある場合は無視
        next if prev_status and prev_status.is_comparable_with?(s)

        @statuses << s
        prev_status = s
      end
    end

    # 履歴表示のために、新しい順にソート
    @statuses = @statuses.sort_by{|s| s.exported_at }.reverse

    # この期間限定海域での新艦娘
    @ships = ShipMaster.where('implemented_at >= ? AND implemented_at < ?', @event.started_at, @event.ended_at)

    # 1枚目のカードから「＊＊改」という名前になっている図鑑No. の配列を作成
    kai_book_numbers = @ships.select{|s| s.ship_name =~ /改$/ }.map{|s| s.book_no }

    # 取得済みのカードを調べた結果
    @cards = {}

    @ships.each do |ship|
      # カードの枚数の配列
      # 取得済みは :acquired、未取得は :not_acquired、存在しない項目は nil を設定
      # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
      if kai_book_numbers.include?(ship.book_no)
        @cards[ship.book_no] = [nil, nil, nil, :not_acquired, :not_acquired, :not_acquired]
      else
        @cards[ship.book_no] = Array.new(ship.variation_num, :not_acquired)
      end

      # イベント期間内に入手した、新艦娘のカードがあるか調べる
      new_cards = ShipCard.where('admiral_id = ? AND book_no = ? AND first_exported_at >= ? AND first_exported_at <= ?',
                                 current_admiral.id, ship.book_no, @event.started_at, @event.ended_at)
      next unless new_cards

      # 新艦娘所持カードのフラグを立てる
      # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
      new_cards.each do |card|
        if kai_book_numbers.include?(card.book_no)
          @cards[card.book_no][card.card_index + 3] = :acquired
        else
          @cards[card.book_no][card.card_index] = :acquired
        end
      end
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
end
