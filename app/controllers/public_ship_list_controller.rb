class PublicShipListController < ApplicationController
  def index
    # 公開設定がない場合は拒否
    @publication = AdmiralPublication.where(url_name: params[:url_name]).first
    if @publication.nil? || @publication.admiral.nil?
      redirect_to root_url
      return
    end

    # 公開設定はあるが、この情報は公開 OFF の場合
    unless @publication.opens_ship_list
      if logged_in? && @publication.admiral.id == current_admiral.id
        # ログインユーザ自身の場合はプレビューを許可
        @preview = true
      else
        # ログインユーザでない場合は拒否
        redirect_to root_url
        return
      end
    end

    set_meta_tags title: "#{@publication.name}提督の艦娘一覧"

    # 以下、ship_list_controller.rb と同じ内容（未実装艦娘の表示機能は除く）
    # ただし、current_admiral.id の代わりに、@publication.admiral_id で検索する
    # TODO Refactoring

    @ships = ShipMaster.where('implemented_at <= ?', Time.now).to_a

    # 「改」があとから実装された艦娘について、ShipMaster を上書き
    UpdatedShipMaster.where('implemented_at <= ?', Time.now).each do |us|
      s = @ships.select{|s| s.book_no == us.book_no }.first
      if s
        @ships.delete(s)
        @ships.push(us)
      end
    end

    # 1枚目のカードから「＊＊改」という名前になっている図鑑No. の配列を作成
    kai_book_numbers = @ships.select{|s| s.ship_name =~ /改$/ }.map{|s| s.book_no }

    # ship_cards および ship_statuses の両方が空の場合は true
    @is_blank = true

    # 取得済みのカードを調べた結果
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

    # 所持カードのフラグを立てる
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    ShipCard.where(admiral_id: @publication.admiral_id).each do |card|
      # 未実装の艦娘のデータが不正にインポートされている場合は、単純にそのデータだけ無視する
      next unless @cards.keys.include?(card.book_no)

      if kai_book_numbers.include?(card.book_no)
        @cards[card.book_no][card.card_index + 3] = :acquired
      else
        @cards[card.book_no][card.card_index] = :acquired
      end
      @is_blank = false
    end

    # 各艦娘の現在のレベルを調べるために、最後にエクスポートされたデータ（レベルも最大値のはず）を取得
    @statuses = {}
    ShipStatus.find_by_sql(
        [ 'SELECT * FROM ship_statuses AS s1 WHERE s1.admiral_id = ? AND NOT EXISTS ' +
              '(SELECT 1 FROM ship_statuses AS s2 ' +
              'WHERE s1.admiral_id = s2.admiral_id AND s1.book_no = s2.book_no ' +
              'AND s1.remodel_level = s2.remodel_level AND s1.exported_at < s2.exported_at)',
          @publication.admiral_id ]
    ).each do |status|
      # 未実装の艦娘のデータが不正にインポートされている場合は、単純にそのデータだけ無視する
      next unless @cards.keys.include?(status.book_no)

      # レベル
      # レベルはノーマルも改も同じなので、両者を区別する必要はない
      @statuses[status.book_no] ||= {}
      @statuses[status.book_no][:level] = status.level

      # 星の数
      # 星の数はノーマルと改で別管理なので、remodel_level で区別する
      # remodel_level = 2 の場合、ノーマルの列に表示する
      @statuses[status.book_no][:star_num] ||= []
      @statuses[status.book_no][:star_num][(status.remodel_level % 2)] = status.star_num

      # 改装設計図の枚数（NULL の場合は 0 と見なす）
      @statuses[status.book_no][:blueprint_total_num] = status.blueprint_total_num
      @statuses[status.book_no][:blueprint_total_num] ||= 0

      # 艦娘一覧が空ではないことを表すフラグを立てる
      @is_blank = false
    end

    # NOTICE 以下は、同一艦娘の特別カードは2枚以上存在しない前提の実装である。2枚以上実装されたら要修正
    # 特別カードの情報
    @special_ships = SpecialShipMaster.all.order(:book_no)

    # 特別カードの入手状況を調べる
    # 取得済みは :acquired、未取得は :not_acquired
    @special_cards = {}
    @special_ships.each do |sship|
      exists = ShipCard.exists?(admiral_id: @publication.admiral_id, book_no: sship.book_no, card_index: sship.card_index)
      @special_cards[sship.book_no] = exists ? :acquired : :not_acquired
    end
  end
end
