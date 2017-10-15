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
end
