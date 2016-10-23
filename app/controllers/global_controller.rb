class GlobalController < ApplicationController
  def ship_card_ownership
    set_meta_tags title: '艦これアーケードの艦娘カード入手率',
                  description: 'Admiral Stats に艦これアーケードのプレイデータをアップロードした提督全体に対する、各艦娘カードを入手済みの提督の割合です。'

    # 集計データのある限定海域
    @campaigns = CampaignMaster.find_by_sql(
        [ 'SELECT * FROM campaign_masters cm' +
              ' WHERE cm.started_at <= ?' +
              ' AND EXISTS (SELECT * FROM campaign_ship_card_ownerships o WHERE cm.campaign_no = o.campaign_no)' +
              ' ORDER BY cm.campaign_no', Time.now ]
    ).to_a

    # URL パラメータ 'all' が true の場合は、未配備の艦娘も表示
    if ActiveRecord::Type::Boolean.new.deserialize(params[:all])
      @ships = ShipMaster.all.to_a
    else
      @ships = ShipMaster.where('implemented_at <= ?', Time.now).to_a
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
  def campaign_ship_card_ownership
    # 集計データのある限定海域
    @campaigns = CampaignMaster.find_by_sql(
        [ 'SELECT * FROM campaign_masters cm' +
              ' WHERE cm.started_at <= ?' +
              ' AND EXISTS (SELECT * FROM campaign_ship_card_ownerships o WHERE cm.campaign_no = o.campaign_no)' +
              ' ORDER BY cm.campaign_no', Time.now ]
    ).to_a

    # 指定された No. の限定海域が存在するかチェック
    @campaign = @campaigns.select{|c| c.campaign_no == params[:campaign_no].to_i }.first
    unless @campaign
      redirect_to root_url
      return
    end

    set_meta_tags title: "艦これアーケードの艦娘カード入手率（#{@campaign.campaign_name}）",
                  description: "期間限定海域「#{@campaign.campaign_name}」出撃後のプレイデータをアップロードした提督全体に対する、各艦娘カードを入手済みの提督の割合です。"

    # この期間限定海域の報酬艦の図鑑 No.
    @reward_book_noes = ShipMaster.where('implemented_at >= ? AND implemented_at < ?',
                                     @campaign.started_at, @campaign.ended_at).map{|s| s.book_no }

    # この期間限定海域の期間に実装されていた艦娘のみを表示
    @ships = ShipMaster.where('implemented_at < ?', @campaign.ended_at).to_a

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

    # この限定海域に関する、最新の集計結果のタイムスタンプを取得
    @last_reported_at = CampaignShipCardOwnership.where(campaign_no: @campaign.campaign_no).maximum(:reported_at)

    # @rates[book_no][card_index] に、カードの取得率を格納
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    @rates = {}
    @cards.keys.each{|book_no| @rates[book_no] = [] }
    CampaignShipCardOwnership.where(campaign_no: @campaign.campaign_no, reported_at: @last_reported_at).each do |own|
      rate = (own.no_of_owners.to_f / own.no_of_active_users * 100).round(1)
      if kai_book_numbers.include?(own.book_no)
        @rates[own.book_no][own.card_index + 3] = rate
      else
        @rates[own.book_no][own.card_index] = rate
      end
    end
  end
end
