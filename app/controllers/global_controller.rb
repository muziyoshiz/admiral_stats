class GlobalController < ApplicationController
  def ship_card_ownership
    set_meta_tags title: '艦これアーケードの艦娘カード入手率',
                  description: 'Admiral Stats に艦これアーケードのプレイデータをアップロードした提督全体に対する、各艦娘カードを入手済みの提督の割合です。'

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
end
