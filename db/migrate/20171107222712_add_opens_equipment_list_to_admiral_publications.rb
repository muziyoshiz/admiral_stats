class AddOpensEquipmentListToAdmiralPublications < ActiveRecord::Migration[5.1]
  def change
    # 装備一覧を公開するかどうか
    add_column :admiral_publications, :opens_equipment_list, :boolean, after: :opens_ship_list, null: false, default: false
  end
end
