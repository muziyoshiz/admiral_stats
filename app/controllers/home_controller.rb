class HomeController < ApplicationController
  before_action :authenticate, except: :index

  def index
    # ホーム画面にだけ色々情報を設定する
    set_meta_tags title: '艦これアーケードのプレイデータ管理ツール',
                  description: 'Admiral Stats は、艦これアーケードのプレイヤーズサイトからエクスポートできる自分のプレイデータを、時系列に可視化するツールです。',
                  # Open Graph Protocol (OGP)
                  og: {
                      # Page title（title と同じ値が設定される）
                      title: :title,
                      type: 'website',
                      image: 'https://www.admiral-stats.com/images/sample.png',
                      # Canonical URL（canonical と同じ値が設定される）
                      url: :canonical,
                      # Site title（site と同じ値が設定される）
                      site_name: :site,
                      # Page description（description と同じ値が設定される）
                      description: :description,
                      locale: 'ja_JP',
                  },
                  # Twitter Card
                  twitter: {
                      # Summary Card with Large Image
                      # https://dev.twitter.com/cards/types/summary-large-image
                      card: 'summary_large_image',
                      site: '@muziyoshiz',
                      title: :title,
                      description: :description,
                      image: 'https://www.admiral-stats.com/images/sample.png',
                  }

    # ログイン前の場合はゲストユーザ用ページを表示
    unless logged_in?
      render :action => 'index_guest'
      return
    end

    # 入手済みのカードのデータを全入手
    ship_cards = ShipCard.where(admiral_id: current_admiral.id)

    # 艦娘図鑑データがない場合
    if ship_cards.blank?
      return
    end

    # 図鑑 No. と ship_master の対応関係
    # TODO この対応関係を毎回データベースに問合せず、キャッシュから取得するように直す
    ship_masters = {}
    ShipMaster.all.each do |master|
      ship_masters[master.book_no] = master
    end

    special_ship_masters = {}
    SpecialShipMaster.all.each do |master|
      special_ship_masters[master.book_no] = master
    end

    # 活動記録を格納する配列
    @histories = []

    # カード種別ごとの数を数えるカウンター
    # 0, 1, 2 -> ノーマルの通常、ホロ、中破
    # 3, 4, 5 -> 改の通常、ホロ、中破
    # 6, 7, 8 -> 改二の通常、ホロ、中破
    counters = Array.new(9, 0)

    # カードをソートするためのインデックス
    index = 0

    ship_cards.sort_by{|c| [ c.first_exported_at, c.book_no ] }.each do |card|
      desc, clazz = nil, nil
      master = ship_masters[card.book_no]

      # TODO (remodel_level, card_index) の組み合わせと、レアリティの対応テーブルを用意して、コード短縮する
      case master.remodel_level
        when 0
          counters[card.card_index] += 1 if card.card_index.between?(0, 5)
          case card.card_index
            when 0
              desc = "#{master.ship_name} が着任しました。"
            when 1
              desc = "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[1]} 隻目のホロです。"
              clazz = 'holo'
            when 2
              desc = "#{master.ship_name}（中破） が着任しました。通算 #{counters[2]} 隻目の中破です。"
              clazz = 'chuha'
            when 3
              desc = "#{master.ship_name}改 が着任しました。通算 #{counters[3]} 隻目の改です。"
              clazz = 'kai'
            when 4
              desc = "#{master.ship_name}改（ホロ） が着任しました。通算 #{counters[4]} 隻目の改（ホロ）です。"
              clazz = 'kai-holo'
            when 5
              desc = "#{master.ship_name}改（中破） が着任しました。通算 #{counters[5]} 隻目の改（中破）です。"
              clazz = 'kai-chuha'
          end
        when 1
          counters[card.card_index + 3] += 1 if card.card_index.between?(0, 2)
          case card.card_index
            when 0
              desc = "#{master.ship_name} が着任しました。通算 #{counters[3]} 隻目の改です。"
              clazz = 'kai'
            when 1
              desc = "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[4]} 隻目の改（ホロ）です。"
              clazz = 'kai-holo'
            when 2
              desc = "#{master.ship_name}（中破） が着任しました。通算 #{counters[5]} 隻目の改（中破）です。"
              clazz = 'kai-chuha'
          end
        when 2
          counters[card.card_index + 6] += 1 if card.card_index.between?(0, 2)
          case card.card_index
            when 0
              desc = "#{master.ship_name} が着任しました。通算 #{counters[6]} 隻目の改二です。"
              clazz = 'kai2'
            when 1
              desc = "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[7]} 隻目の改二（ホロ）です。"
              clazz = 'kai2-holo'
            when 2
              desc = "#{master.ship_name}（中破） が着任しました。通算 #{counters[8]} 隻目の改二（中破）です。"
              clazz = 'kai2-chuha'
          end
      end

      # 通常の艦娘カードのマスタデータに含まれない場合は、限定カードから探す
      unless desc
        sp_master = special_ship_masters[card.book_no]
        if sp_master
          case sp_master.remodel_level
            when 1
              case sp_master.rarity
                when 1
                  counters[4] += 1
                  desc = "#{master.ship_name}（ホロ・限定カード） が着任しました。通算 #{counters[4]} 隻目の改（ホロ）です。"
                  clazz = 'kai-holo'
              end
              # TODO 他の分岐も足す
          end
        end
      end

      if desc
        @histories << {
            :exported_at => card.first_exported_at.to_s(:datetime),
            :index => index,
            :description => desc,
            :class => clazz,
        }

        index += 1
      end
    end
  end
end
