class AdmiralInfoController < ApplicationController
  before_action :authenticate

  # 暫定順位が「圏外」だった場合に、仮に表示する数値
  # @sophiarcp さんの検証結果によると、3000 位近辺がボーダーと思われる
  RANK_KENGAI = 3100

  # 提督の基本情報を表示します。
  def index
    set_meta_tags title: '提督情報'

    # 表示期間の指定（デフォルトは過去1ヶ月）
    if params[:range] and params[:range] == 'all'
      @range = :all

      # 提督情報を一括取得
      admiral_statuses = AdmiralStatus.where(admiral_id: current_admiral.id).order(exported_at: :asc)
    else
      @range = :month

      # 過去1ヶ月分の提督情報を一括取得
      admiral_statuses = AdmiralStatus.where(admiral_id: current_admiral.id, exported_at: 1.month.ago..Time.current).
          order(exported_at: :asc)
    end

    # 提督情報がなければ、処理を終了
    if admiral_statuses.blank?
      render :action => 'index_blank'
      return
    end

    # 最大備蓄可能各資源量
    latest_status = admiral_statuses.last
    @level_max, @material_max = latest_status.level, latest_status.level_to_material_max

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
        # 暫定順位は '圏外' または 数値 で返されると思われる（'圏外' しか見たこと無いので、あくまで推測）
        # 中身が数値の場合はその数値をプロットし、それ以外の場合は仮に 100,000 位とする
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

    set_meta_tags title: "イベントの進捗（#{@event.event_name}）"

    # 積集合を取ることで、難易度の並び順を保つ
#    @levels = %w(HEI OTU KOU) & EventProgressStatus.select(:level).where(admiral_id: current_admiral.id).distinct
    @levels = %w(HEI OTU)

    @statuses = {}
    @current_loop_counts = {}
    @cleared_loop_counts = {}
    # cleared_area_sub_id を、E-1 なら 1、E-2 なら 2 といったステージ番号に変換したもの
    @cleared_stage_no = {}

    @levels.each do |level|
      # 履歴表示のために、新しい順にソート
      @statuses[level] = EventProgressStatus.where(
          admiral_id: current_admiral.id, event_no: @event.event_no, level: level).order(exported_at: :desc).to_a

      latest = @statuses[level].first
      @current_loop_counts[level] = latest.current_loop_counts
      @cleared_loop_counts[level] = latest.cleared_loop_counts

      # その難易度の E-1 に対応する area_sub_id
      case level
        when 'HEI'
          first_area_sub_id = 1
        when 'OTU'
          first_area_sub_id = 6
      end

      if latest.cleared_area_sub_id == 0
        @cleared_stage_no[level] = 0
      else
        @cleared_stage_no[level] = latest.cleared_area_sub_id - first_area_sub_id + 1
      end
    end
  end
end
