class ShipListController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: '艦娘一覧'

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

    # ship_cards および ship_statuses の両方が空の場合は true
    @is_blank = true

    # 取得済みのカードを調べた結果
    @cards = {}

    # カードの枚数の配列
    # 取得済みは :acquired、未取得は :not_acquired、存在しない項目は nil を設定
    # ただし、表示名が「＊＊改」のカード（remodel_level = 1 のカード）については、
    # index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    @ships.each do |ship|
      if ship.is_kai?
        @cards[ship.book_no] = [nil, nil, nil, :not_acquired, :not_acquired, :not_acquired]
      else
        @cards[ship.book_no] = Array.new(ship.variation_num, :not_acquired)
      end
    end

    # 所持カードのフラグを立てる
    # ただし、表示名が「＊＊改」のカードについては、index に 3 加算して配列に入れる（「改」の列に表示されるようにする）
    ShipCard.where(admiral_id: current_admiral.id).includes(:ship_master).each do |card|
      # 未実装の艦娘のデータが不正にインポートされている場合は、単純にそのデータだけ無視する
      next unless @cards.keys.include?(card.book_no)

      # 艦娘一覧の表示範囲かどうかを判定し、必要に応じて表示位置を補正
      idx = card.index_for_ship_list
      if idx
        @cards[card.book_no][idx] = :acquired
        @is_blank = false
      end
    end

    # 各艦娘の現在のレベルを調べるために、最後にエクスポートされたデータ（レベルも最大値のはず）を取得
    last_exported_at = ShipStatus.where(admiral_id: current_admiral.id).maximum(:exported_at)

    @statuses = {}
    ShipStatus.where(admiral_id: current_admiral.id, exported_at: last_exported_at).each do |status|
      # 未実装の艦娘のデータが不正にインポートされている場合は、単純にそのデータだけ無視する
      next unless @cards.keys.include?(status.book_no)

      # レベル
      # レベルはノーマルも改も同じなので、両者を区別する必要はない
      @statuses[status.book_no] ||= {}
      @statuses[status.book_no][:level] = status.level

      # 星の数および婚姻状態は remodel_level ごとに別管理
      ship = @ships.select{|s| s.book_no == status.book_no }.first
      if ship
        @statuses[ship.book_no][:star_num] ||= []
        @statuses[ship.book_no][:married] ||= []

        if ship.variation_num == 3 && ship.remodel_level == 1
          # 表示名が「＊＊改」のカードの場合、2列目に表示
          @statuses[status.book_no][:star_num][1] = status.star_num
          @statuses[status.book_no][:married][1] = status.married
        elsif ship.variation_num == 6 && ship.remodel_level < status.remodel_level
          # 改二以上のカードで、remodel_level が ShipMaster の remodel_level より高い場合、2列目に表示
          # 千歳航改、千代田航改はこのパターンに該当する
          @statuses[status.book_no][:star_num][1] = status.star_num
          @statuses[status.book_no][:married][1] = status.married
        else
          # 上記以外の場合は1列目に表示
          @statuses[status.book_no][:star_num][0] = status.star_num
          @statuses[status.book_no][:married][0] = status.married
        end
      end

      # 改装設計図の枚数（NULL の場合は 0 と見なす）
      @statuses[status.book_no][:blueprint_total_num] = status.blueprint_total_num
      @statuses[status.book_no][:blueprint_total_num] ||= 0

      # 艦娘一覧が空ではないことを表すフラグを立てる
      @is_blank = false
    end

    # 特別カードの情報
    @special_ships = SpecialShipMaster.where('implemented_at <= ?', Time.current).order(:book_no, :implemented_at)

    # 特別カードの入手状況を調べる
    # 取得済みは :acquired、未取得は :not_acquired
    # 同一艦娘の特別カードが2枚以上存在しても動作するように、@special_cards のキーに SpecialShipMaster を設定
    @special_cards = {}
    @special_ships.each do |sship|
      exists = ShipCard.exists?(admiral_id: current_admiral.id, book_no: sship.book_no, card_index: sship.card_index)
      @special_cards[sship] = exists ? :acquired : :not_acquired
    end
  end

  # 各艦娘の装備スロットの一覧表示です。
  def slot
    set_meta_tags title: '艦娘一覧（装備スロット）'

    # ship_statuses の最終エクスポート時刻を取得
    # ship_statuses がない場合は、返り値は nil
    last_exported_at = ShipStatus.where(admiral_id: current_admiral.id).maximum('exported_at')

    # ship_master, ship_slot_statuses レコードも含めて一度に取得
    @statuses = ShipStatus.includes(:ship_master, :ship_slot_statuses).where(admiral_id: current_admiral.id, exported_at: last_exported_at)
    @statuses = @statuses.reject{|st| st.ship_master.nil? }
  end

  # 各艦娘の改装設計図の一覧表示です。
  def blueprint
    set_meta_tags title: '改装設計図一覧'

    # blueprint_statuses の最終エクスポート時刻を取得
    # blueprint_statuses がない場合は、返り値は nil
    last_exported_at = BlueprintStatus.where(admiral_id: current_admiral.id).maximum('exported_at')

    # ship_masters レコードも含めて一度に取得
    @statuses = BlueprintStatus.includes(:ship_master).where(admiral_id: current_admiral.id, exported_at: last_exported_at)
    @statuses = @statuses.reject{|st| st.ship_master.nil? }
  end
end
