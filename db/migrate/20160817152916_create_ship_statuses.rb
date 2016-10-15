class CreateShipStatuses < ActiveRecord::Migration[5.0]
  def change
    # 艦娘のレベルおよび改造状態
    create_table :ship_statuses do |t|
      # 提督 ID
      t.integer  :admiral_id,    :null => false

      # 艦娘図鑑の図鑑 No.
      t.integer  :book_no,       :null => false

      # 解像度合いを表す数値
      # （未改造の艦娘と、改造済みの艦娘が、別のデータとして返される）
      # 0: 未改造
      # 1: 改
      t.integer  :remodel_level, :null => false

      # レベル
      t.integer  :level,         :null => false

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,   :null => false

      # Index name is too long; the limit is 64 characters エラーを回避するために、インデックス名を指定
      t.index [:admiral_id, :book_no, :remodel_level, :exported_at], :unique => true, :name => 'index_ship_statuses'
    end
  end
end
