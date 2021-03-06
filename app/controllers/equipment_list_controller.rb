class EquipmentListController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: '装備一覧'

    # 実装済みの装備すべて
    @equipments = EquipmentMaster.where('implemented_at <= ?', Time.now)

    # 取得済みの装備の図鑑 No.
    @owned_book_noes = EquipmentCard.where(admiral_id: current_admiral.id).select(:book_no).order(:book_no).map(&:book_no)

    # 各装備の現在の個数を調べるために、最後にエクスポートされた時刻を取得
    # 艦娘一覧のように、1回のクエリで取得しようとするとうまくいかない（件数が0件になった装備については、新しいレコードが作られないため）
    last_exported_at = EquipmentStatus.where(admiral_id: current_admiral.id).maximum(:exported_at)

    @statuses = {}
    EquipmentStatus.where(admiral_id: current_admiral.id, exported_at: last_exported_at).each do |status|
      @statuses[status.equipment_id] = status
    end

    # equipment_cards および equipment_statuses の両方が空の場合は true
    @is_blank = (@statuses.size == 0 && @owned_book_noes.size == 0)
  end

  def show
    @equipment = EquipmentMaster.find_by_book_no(params[:book_no])

    # 指定された図鑑 No. の装備がない場合は、装備一覧に移動
    unless @equipment
      redirect_to controller: 'equipment_list'
      return
    end

    set_meta_tags title: "装備情報: #{@equipment.equipment_name}"

    # 表示期間の指定（デフォルトは過去1ヶ月）
    @range = ShipInfoController.get_range_symbol(params[:range])

    if @range == :all
      timestamps = EquipmentCardTimestamp.where(admiral_id: current_admiral.id).order(exported_at: :asc).map(&:exported_at)
      equip_statuses = EquipmentStatus.where(admiral_id: current_admiral.id, equipment_id: @equipment.equipment_id)
    else
      beginning_of_range = ShipInfoController.get_beginning_of_range_by(@range)

      timestamps = EquipmentCardTimestamp.where(admiral_id: current_admiral.id, exported_at: beginning_of_range..Time.current).
          order(exported_at: :asc).map{|t| t.exported_at }
      equip_statuses = EquipmentStatus.where(admiral_id: current_admiral.id, equipment_id: @equipment.equipment_id,
                                             exported_at: beginning_of_range..Time.current)

      # 指定された期間にデータがなければ、範囲を全期間に変えて検索し直す
      if timestamps.blank?
        @error = '指定された期間にデータが存在しなかったため、全期間のデータを表示します。'
        @range = :all

        timestamps = EquipmentCardTimestamp.where(admiral_id: current_admiral.id).order(exported_at: :asc).map(&:exported_at)
        equip_statuses = EquipmentStatus.where(admiral_id: current_admiral.id, equipment_id: @equipment.equipment_id)
      end
    end

    # 全体の数および割合を計算
    num_data = []
    timestamps.each do |exported_at|
      timestamp = exported_at.to_i * 1000

      equip_status = equip_statuses.select{|es| es.exported_at == exported_at }.first
      num_data << [ timestamp, (equip_status ? equip_status.num : 0) ]
    end
    @series_num = [{ 'name' => @equipment.equipment_name, 'data' => num_data }]

    # ship_statuses の最終エクスポート時刻を取得
    # ship_statuses がない場合は、返り値は nil
    last_exported_at = ShipStatus.where(admiral_id: current_admiral.id).maximum('exported_at')

    # ship_master, ship_slot_statuses レコードも含めて一度に取得
    @statuses = ShipStatus.includes(:ship_master, :ship_slot_statuses).where(admiral_id: current_admiral.id, exported_at: last_exported_at)
    @statuses = @statuses.reject{|st| st.ship_master.nil? }

    # その装備を装備中の ship_statuses を抽出
    @equipped_statuses = @statuses.select{|s| s.ship_slot_statuses.map(&:slot_equip_name).include?(@equipment.equipment_name) }
  end
end
