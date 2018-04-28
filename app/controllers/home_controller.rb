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
    ship_cards = ShipCard.where(admiral_id: current_admiral.id).includes(:ship_master)

    # 艦娘図鑑データがない場合
    if ship_cards.blank?
      return
    end

    special_ship_masters = {}
    SpecialShipMaster.all.each do |master|
      special_ship_masters[master.book_no] ||= {}
      special_ship_masters[master.book_no][master.card_index] = master
    end

    # 活動記録を格納する配列
    @histories = []

    # カード種別ごとの数を数えるカウンター
    # 0, 1, 2 -> ノーマルの通常、ホロ、中破
    # 3, 4, 5 -> 改の通常、ホロ、中破
    # 6, 7, 8 -> 改二の通常、ホロ、中破
    # 9, 10, 11 -> 改三以上の通常、ホロ、中破
    counters = Array.new(12, 0)

    # カードをソートするためのインデックス
    index = 0

    ship_cards.sort_by{|c| [ c.first_exported_at, c.book_no ] }.each do |card|
      # 活動記録への表示内容を取得する
      desc, clazz = resolve_desc_and_clazz(card, counters)

      # 通常の艦娘カードのマスタデータに含まれない場合は、限定カードから探す
      # TODO 今後、限定カードのレアリティが増えたら、分岐を書き足す（コードが無駄に長くなるので、全パターンは書かない）
      unless desc
        master = card.ship_master
        sp_master = special_ship_masters[card.book_no][card.card_index]
        if sp_master
          card_index = sp_master.remodel_level * 3 + sp_master.rarity
          counters[card_index] += 1

          case sp_master.remodel_level
            when 0
              case sp_master.rarity
                when 1
                  desc = "#{master.ship_name}（ホロ・限定カード） が着任しました。通算 #{counters[card_index]} 隻目のホロです。"
                  clazz = 'holo'
              end
            when 1
              # 辞書の艦娘名に「改」を付ける必要があるかどうかを判定
              kai = '改' if sp_master.card_index == 6

              case sp_master.rarity
                when 1
                  desc = "#{master.ship_name}#{kai}（ホロ・限定カード） が着任しました。通算 #{counters[card_index]} 隻目の改（ホロ）です。"
                  clazz = 'kai-holo'
              end
            when 2
              case sp_master.rarity
                when 0
                  desc = "#{master.ship_name}（限定カード） が着任しました。通算 #{counters[card_index]} 隻目の改二です。"
                  clazz = 'kai2'
                when 1
                  desc = "#{master.ship_name}（ホロ・限定カード） が着任しました。通算 #{counters[card_index]} 隻目の改二（ホロ）です。"
                  clazz = 'kai2-holo'
              end
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

  private

  # 艦娘カードの情報から、活動記録に表示する説明文と、CSS のクラス名を解決して返します。
  # また、カウンターにカード枚数を加算します。
  def resolve_desc_and_clazz(card, counters)
    master = card.ship_master
    card_index = card.card_index

    if master.book_no == 205
      case card_index
        when 3
          # 限定カードの場合はこの処理全体をスキップ
          return nil, nil
        when 4..6
          # 春雨改の card_index を補正
          card_index -= 1
      end
    end

    # TODO (remodel_level, card_index) の組み合わせと、レアリティの対応テーブルを用意して、コード短縮する
    case master.remodel_level
      when 0
        counters[card_index] += 1 if card_index.between?(0, 5)
        case card_index
          when 0
            return "#{master.ship_name} が着任しました。", nil
          when 1
            return "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[1]} 隻目のホロです。", 'holo'
          when 2
            return "#{master.ship_name}（中破） が着任しました。通算 #{counters[2]} 隻目の中破です。", 'chuha'
          when 3
            return "#{master.ship_name}改 が着任しました。通算 #{counters[3]} 隻目の改です。", 'kai'
          when 4
            return "#{master.ship_name}改（ホロ） が着任しました。通算 #{counters[4]} 隻目の改（ホロ）です。", 'kai-holo'
          when 5
            return "#{master.ship_name}改（中破） が着任しました。通算 #{counters[5]} 隻目の改（中破）です。", 'kai-chuha'
        end
      when 1
        counters[card_index + 3] += 1 if card_index.between?(0, 2)
        case card_index
          when 0
            return "#{master.ship_name} が着任しました。通算 #{counters[3]} 隻目の改です。", 'kai'
          when 1
            return "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[4]} 隻目の改（ホロ）です。", 'kai-holo'
          when 2
            return "#{master.ship_name}（中破） が着任しました。通算 #{counters[5]} 隻目の改（中破）です。", 'kai-chuha'
        end
      when 2
        counters[card_index + 6] += 1 if card_index.between?(0, 2)
        case card_index
          when 0
            return "#{master.ship_name} が着任しました。通算 #{counters[6]} 隻目の改二です。", 'kai2'
          when 1
            return "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[7]} 隻目の改二（ホロ）です。", 'kai2-holo'
          when 2
            return "#{master.ship_name}（中破） が着任しました。通算 #{counters[8]} 隻目の改二（中破）です。", 'kai2-chuha'
        end
      when 3..5
        # remodel_level が 3 以上の艦娘は、すべて「改三以上」として扱う
        counters[(card_index % 3) + 9] += 1 if card_index.between?(0, 5)

        # 艦娘名表示は、名前に「改」を付けるか付けないかを判断するために、remodel_level で処理を分岐する必要がある
        case master.remodel_level
          when 3
            # 千歳航、千代田航、およびコンバート艦娘がここに該当
            case card_index
              when 0
                return "#{master.ship_name} が着任しました。通算 #{counters[9]} 隻目の改三以上です。", 'kai3'
              when 1
                return "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[10]} 隻目の改三以上（ホロ）です。", 'kai3-holo'
              when 2
                return "#{master.ship_name}（中破） が着任しました。通算 #{counters[11]} 隻目の改三以上（中破）です。", 'kai3-chuha'
              when 3
                return "#{master.ship_name}改 が着任しました。通算 #{counters[9]} 隻目の改三以上です。", 'kai3'
              when 4
                return "#{master.ship_name}改（ホロ） が着任しました。通算 #{counters[10]} 隻目の改三以上（ホロ）です。", 'kai3-holo'
              when 5
                return "#{master.ship_name}改（中破） が着任しました。通算 #{counters[11]} 隻目の改三以上（中破）です。", 'kai3-chuha'
            end
          when 5
            # 千歳航改二、千代田航改二のみがここに該当
            case card_index
              when 0
                return "#{master.ship_name} が着任しました。通算 #{counters[9]} 隻目の改三以上です。", 'kai3'
              when 1
                return "#{master.ship_name}（ホロ） が着任しました。通算 #{counters[10]} 隻目の改三以上（ホロ）です。", 'kai3-holo'
              when 2
                return "#{master.ship_name}（中破） が着任しました。通算 #{counters[11]} 隻目の改三以上（中破）です。", 'kai3-chuha'
            end
        end
    end

    return nil, nil
  end
end
