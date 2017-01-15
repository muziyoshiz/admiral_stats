class ShipListController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: '艦娘一覧'

    # URL パラメータ 'all' が true の場合は、未配備の艦娘も表示
    if ActiveRecord::Type::Boolean.new.deserialize(params[:all])
      @ships = ShipMaster.all.to_a
    else
      @ships = ShipMaster.where('implemented_at <= ?', Time.now).to_a
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
    ShipCard.where(admiral_id: current_admiral.id).each do |card|
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
          current_admiral.id ]
    ).each do |status|
      # レベル
      # レベルはノーマルも改も同じなので、両者を区別する必要はない
      @statuses[status.book_no] ||= {}
      @statuses[status.book_no][:level] = status.level

      # 星の数
      # 星の数はノーマルと改で別管理なので、remodel_level で区別する
      @statuses[status.book_no][:star_num] ||= []
      @statuses[status.book_no][:star_num][status.remodel_level] = status.star_num

      # 艦娘一覧が空ではないことを表すフラグを立てる
      @is_blank = false
    end
  end

  # 各艦娘の装備スロットの一覧表示です。
  def slot
    set_meta_tags title: '艦娘一覧（装備スロット）'

    # 実装済みの艦娘のみ取得
    @ships = {}
    ShipMaster.where('implemented_at <= ?', Time.now).each{|ship| @ships[ship.book_no] = ship }

    # ship_statuses の最終エクスポート時刻を取得
    # ship_statuses がない場合は、返り値は nil
    last_exported_at = ShipStatus.where(admiral_id: current_admiral.id).maximum('exported_at')

    # ship_slot_statuses レコードも含めて一度に取得
    @statuses = ShipStatus.includes(:ship_slot_statuses).where(admiral_id: current_admiral.id, exported_at: last_exported_at).
        order(book_no: :asc, remodel_level: :asc)
  end
end
