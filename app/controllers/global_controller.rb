class GlobalController < ApplicationController
  def ship_card_ownership
    set_meta_tags title: '艦これアーケードの艦娘カード入手率',
                  description: 'Admiral Stats に艦これアーケードのプレイデータをアップロードした提督全体に対する、各艦娘カードを入手済みの提督の割合です。'

    # 集計データのある限定海域
    @events = EventMaster.find_by_sql(
        [ 'SELECT * FROM event_masters em' +
              ' WHERE em.started_at <= ?' +
              ' AND EXISTS (SELECT * FROM event_ship_card_ownerships o WHERE em.event_no = o.event_no)' +
              ' ORDER BY em.event_no', Time.now ]
    ).to_a

    # URL パラメータ 'all' が true の場合は、未配備の艦娘も表示
    if ActiveRecord::Type::Boolean.new.deserialize(params[:all])
      @ships = ShipMaster.all.to_a
    else
      @ships = ShipMaster.where('implemented_at <= ?', Time.now).to_a

      # 「改」があとから実装された艦娘について、ShipMaster を上書き
      UpdatedShipMaster.where('implemented_at <= ?', Time.now).each do |us|
        s = @ships.select{|s| s.book_no == us.book_no }.first
        if s
          @ships.delete(s)
          @ships.push(us)
        end
      end
    end

    # 1枚目のカードから「＊＊改」という名前になっている図鑑No. の配列を作成
    kai_book_numbers = @ships.select{|s| s.ship_name =~ /改$/ }.map{|s| s.book_no }

    # 各カードについて、カードあり（取得済み）、カードあり（未取得）、カードなしのいずれかのフラグを格納するハッシュ
    # 未ログインの場合は、カードあり（未取得）、カードなしのいずれかを格納する
    @cards = {}

    # カードの枚数の配列
    # 取得済みは :acquired、未取得は :not_acquired、存在しない項目は nil を設定
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    @ships.each do |ship|
      if kai_book_numbers.include?(ship.book_no)
        @cards[ship.book_no] = [nil, nil, nil, :not_acquired, :not_acquired, :not_acquired]
      else
        @cards[ship.book_no] = Array.new(ship.variation_num, :not_acquired)
      end
    end

    # ログイン中の場合は、所持カードのフラグを立てる
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    if logged_in?
      ShipCard.where(admiral_id: current_admiral.id).each do |card|
        if kai_book_numbers.include?(card.book_no)
          @cards[card.book_no][card.card_index + 3] = :acquired
        else
          @cards[card.book_no][card.card_index] = :acquired
        end
      end
    end

    # 最新の集計結果のタイムスタンプを取得
    @last_reported_at = ShipCardOwnership.maximum(:reported_at)

    # @rates[book_no][card_index] に、カードの取得率を格納
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    @rates = {}
    @cards.keys.each{|book_no| @rates[book_no] = [] }
    ShipCardOwnership.where(reported_at: @last_reported_at).each do |own|
      rate = (own.no_of_owners.to_f / own.no_of_active_users * 100).round(1)
      if kai_book_numbers.include?(own.book_no)
        @rates[own.book_no][own.card_index + 3] = rate
      else
        @rates[own.book_no][own.card_index] = rate
      end
    end
  end

  # 特定の限定海域に関する情報を表示する
  def event_ship_card_ownership
    # 集計データのあるイベント
    @events = EventMaster.find_by_sql(
        [ 'SELECT * FROM event_masters em' +
              ' WHERE em.started_at <= ?' +
              ' AND EXISTS (SELECT * FROM event_ship_card_ownerships o WHERE em.event_no = o.event_no)' +
              ' ORDER BY em.event_no', Time.now ]
    ).to_a

    # 指定された No. のイベントが存在するかチェック
    @event = @events.select{|e| e.event_no == params[:event_no].to_i }.first
    unless @event
      redirect_to root_url
      return
    end

    set_meta_tags title: "艦これアーケードの艦娘カード入手率（#{@event.event_name}）",
                  description: "期間限定海域「#{@event.event_name}」出撃後のプレイデータをアップロードした提督全体に対する、各艦娘カードを入手済みの提督の割合です。"

    # この期間限定海域での新艦娘の図鑑 No.
    @reward_book_noes = ShipMaster.where('implemented_at >= ? AND implemented_at < ?',
                                         @event.started_at, @event.ended_at).map{|s| s.book_no }

    # この期間限定海域の期間に実装されていた艦娘のみを表示
    @ships = ShipMaster.where('implemented_at < ?', @event.ended_at).to_a
    # 「改」があとから実装された艦娘について、ShipMaster を上書き
    UpdatedShipMaster.where('implemented_at < ?', @event.ended_at).each do |us|
      s = @ships.select{|s| s.book_no == us.book_no }.first
      if s
        @ships.delete(s)
        @ships.push(us)
      end
    end

    # 1枚目のカードから「＊＊改」という名前になっている図鑑No. の配列を作成
    kai_book_numbers = @ships.select{|s| s.ship_name =~ /改$/ }.map{|s| s.book_no }

    # 各カードについて、カードあり（取得済み）、カードあり（未取得）、カードなしのいずれかのフラグを格納するハッシュ
    # 未ログインの場合は、カードあり（未取得）、カードなしのいずれかを格納する
    @cards = {}

    # カードの枚数の配列
    # 取得済みは :acquired、未取得は :not_acquired、存在しない項目は nil を設定
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    @ships.each do |ship|
      if kai_book_numbers.include?(ship.book_no)
        @cards[ship.book_no] = [nil, nil, nil, :not_acquired, :not_acquired, :not_acquired]
      else
        @cards[ship.book_no] = Array.new(ship.variation_num, :not_acquired)
      end
    end

    # ログイン中の場合は、所持カードのフラグを立てる
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    if logged_in?
      ShipCard.where(admiral_id: current_admiral.id).each do |card|
        # イベント期間中に実装されていなかった艦娘は除外する
        next unless @cards.keys.include?(card.book_no)

        if kai_book_numbers.include?(card.book_no)
          @cards[card.book_no][card.card_index + 3] = :acquired
        else
          @cards[card.book_no][card.card_index] = :acquired
        end
      end
    end

    # この限定海域に関する、最新の集計結果のタイムスタンプを取得
    @last_reported_at = EventShipCardOwnership.where(event_no: @event.event_no).maximum(:reported_at)

    # @rates[book_no][card_index] に、カードの取得率を格納
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    @rates = {}
    @cards.keys.each{|book_no| @rates[book_no] = [] }
    EventShipCardOwnership.where(event_no: @event.event_no, reported_at: @last_reported_at).each do |own|
      rate = (own.no_of_owners.to_f / own.no_of_active_users * 100).round(1)
      if kai_book_numbers.include?(own.book_no)
        @rates[own.book_no][own.card_index + 3] = rate
      else
        @rates[own.book_no][own.card_index] = rate
      end
    end
  end

  # イベント攻略率を表示する
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

    set_meta_tags title: "イベント攻略率（#{@event.event_name}）"

    # 各提督の、攻略済み周回数を、難易度別に取得
    @statuses = {}
    @event.levels.each do |level|
      @statuses[level] = EventProgressStatus.find_by_sql(
          [ 'SELECT admiral_id, max(cleared_loop_counts) AS max_cleared_loop_counts ' +
                'FROM event_progress_statuses WHERE level = ? GROUP BY admiral_id',
            level ]
      )
    end

    # アップロード済みの提督数
    @total_num = @statuses.map{|level, ss| ss.size }.max

    # クリアした提督数
    @cleared_nums = {}
    @event.levels.each do |level|
      @cleared_nums[level] = @statuses[level].select{|s| s.max_cleared_loop_counts > 0 }.size
    end
    # 丙難易度をクリア済みの人数から、乙難易度をクリア済みの人数を引く
    higher_level_cleared_nums = 0
    @event.levels.reverse.each do |level|
      @cleared_nums[level] -= higher_level_cleared_nums
      higher_level_cleared_nums = @cleared_nums[level]
    end

    # クリアした周回数
    @cleared_loop_counts = {}
    @event.levels.each do |level|
      @cleared_loop_counts[level] = []
      (0..9).each do |cnt|
        @cleared_loop_counts[level][cnt] = @statuses[level].select{|s| s.max_cleared_loop_counts == cnt }.size
      end

      @cleared_loop_counts[level][10] = @statuses[level].select{|s| s.max_cleared_loop_counts >= 10 and s.max_cleared_loop_counts < 20 }.size
      @cleared_loop_counts[level][11] = @statuses[level].select{|s| s.max_cleared_loop_counts >= 20 and s.max_cleared_loop_counts < 30 }.size
      @cleared_loop_counts[level][12] = @statuses[level].select{|s| s.max_cleared_loop_counts >= 30 and s.max_cleared_loop_counts < 40 }.size
      @cleared_loop_counts[level][13] = @statuses[level].select{|s| s.max_cleared_loop_counts >= 40 and s.max_cleared_loop_counts < 50 }.size
      @cleared_loop_counts[level][14] = @statuses[level].select{|s| s.max_cleared_loop_counts >= 50 }.size
    end
  end
end
