class CreateAdmiralStatuses < ActiveRecord::Migration[5.0]
  def change
    # 提督のレベルなどの状態
    create_table :admiral_statuses do |t|
      # 提督 ID
      t.integer  :admiral_id,     null: false

      # 燃料
      t.integer  :fuel,           null: false

      # 弾薬
      t.integer  :ammo,           null: false

      # 鋼材
      t.integer  :steel,          null: false

      # ボーキサイト
      t.integer  :bauxite,        null: false

      # 修復バケツ
      t.integer  :bucket,         null: false

      # 艦隊司令部Level
      t.integer  :level,          null: false

      # 家具コイン
      t.integer  :room_item_coin, null: false

      # 戦果 (From API version 2)
      # 戦果は数値だが、なぜか STRING 型で返される。どういう場合に文字列が返されるのかわからないが、
      # 念のため string で格納する
      t.string   :result_point,   limit: 32

      # 暫定順位 (From API version 2)
      # 数値または「圏外」
      t.string   :rank,           limit: 32

      # 階級を表す数値 (From API version 2)
      t.integer  :title_id

      # 戦略ポイント (From API version 2)
      t.integer  :strategy_point

      # SEGA の「提督情報」からエクスポートされた日時
      t.datetime :exported_at,   null: false

      t.index [:admiral_id, :exported_at], unique: true
    end
  end
end
