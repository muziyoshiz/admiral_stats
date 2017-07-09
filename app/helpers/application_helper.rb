module ApplicationHelper
  # ログイン状態の場合はリンク表示し、そうでない場合は文字列のみを表示する
  def link_to_if_logged_in(name = nil, options = nil, html_options = nil, &block)
    if logged_in?
      link_to name, options, html_options, &block
    else
      name
    end
  end

  # 期間を表すシンボルを、文字表現に変換します。
  def range_to_s(range)
    case range
      when :month
        '過去 1 ヶ月'
      when :three_months
        '過去 3 ヶ月'
      when :half_year
        '過去 6 ヶ月'
      when :year
        '過去 1 年'
      when :all
        '全期間'
      else
        '?'
    end
  end

  # 期間を表すシンボルすべてを含む配列を返します。
  def range_symbols
    [:month, :three_months, :half_year, :year, :all]
  end

  # 特別カードの階層レベルおよびレアリティを、文字表現に変換します。
  def special_ship_rarity_to_s(special_ship)
    first_half = case special_ship.remodel_level
                   when 0
                     'N'
                   when 1
                     '改'
                   when 2
                     '改二'
                 end
    latter_half = case special_ship.rarity
                    when 1
                      'ホロ'
                    when 2
                      '中破'
                  end

    first_half + latter_half
  end

  # イベント難易度を日本語表記に変換します。
  def difficulty_level_to_text(level)
    case level
      when 'HEI'
        '丙'
      when 'OTU'
        '乙'
      when 'KOU'
        '甲'
    end
  end

  # イベント難易度を色設定に変換します。
  def difficulty_level_to_color(level)
    case level
      when 'HEI'
        '#1AA94D'
      when 'OTU'
        '#D5B606'
      when 'KOU'
        # TODO 甲難易度が登場したら、プレイヤーズサイトの表示を見て、色を設定する
        '#AA0000'
    end
  end

  # 階級を表す数値を、階級の名前に変換します。
  def title_id_to_title(title_id)
    case title_id
      when 0
        '新米少佐'
      when 1
        '中堅少佐'
      when 2
        '少佐'
      when 3
        '新米中佐'
      when 4
        '中佐'
      when 5
        '大佐'
      when 6
        '少将'
      when 7
        '中将'
      when 8
        '大将'
      when 9
        '元帥'
      when 10
        '集計中'
      else
        '？'
    end
  end

  # 差分を表す <span> タグを返します。
  def h_span_for_delta(first_val, last_val, ndigits = 1)
    # いずれかに文字列などを含む場合は、何も返さない
    return '' unless (first_val.is_a?(Numeric) and last_val.is_a?(Numeric))

    delta = last_val - first_val
    if delta.is_a?(Float)
      delta = delta.round(ndigits)
    end

    if delta > 0
      <<~SPAN
        <br><span class="increase"><i class="glyphicon glyphicon-arrow-up"></i> #{number_with_delimiter(delta)}</span>
      SPAN
    elsif delta < 0
      <<~SPAN
        <br><span class="decrease"><i class="glyphicon glyphicon-arrow-down"></i> #{number_with_delimiter(delta * -1)}</span>
      SPAN
    else
      <<~SPAN
        <br><span class="same"><i class="glyphicon glyphicon-arrow-right"></i> 0</span>
      SPAN
    end
  end

  # SEGA 公式のプレイヤーズサイトの URL を返します。
  def sega_url
    'https://kancolle-arcade.net/ac/#/top'
  end

  # admiral_stats_exporter の URL を返します。
  def exporter_url
    'https://github.com/muziyoshiz/admiral_stats_exporter'
  end

  # @muziyoshiz の URL を返します。
  def twitter_muziyoshiz_url
    'https://twitter.com/muziyoshiz'
  end

  # @admiral_stats の URL を返します。
  def twitter_admiral_stats_url
    'https://twitter.com/admiral_stats'
  end

  # Admiral Stats 本体の GitHub リポジトリの URL を返します。
  def github_url
    'https://github.com/muziyoshiz/admiral_stats'
  end

  # Admiral Stats 用のチャットルームの URL を返します。
  def gitter_url
    'https://gitter.im/muziyoshiz/admiral_stats'
  end

  def link_to_exporter_url
    link_to 'admiral_stats_exporter', exporter_url, :target => '_blank'
  end

  def link_to_twitter_muziyoshiz
    link_to '@muziyoshiz', twitter_muziyoshiz_url, :target => '_blank'
  end

  def link_to_twitter_admiral_stats
    link_to '@admiral_stats', twitter_admiral_stats_url, :target => '_blank'
  end

  # meta-tags に渡すデフォルト値
  def default_meta_tags
    {
        # Site title
        site: 'Admiral Stats',
        # Page title
        title: '',
        # Page description
        description: '',
        # Page keywords
        keywords: '艦隊これくしょん, 艦これ, 艦これアーケード, 艦これArcade, 艦これAC, 艦アケ, プレイデータ, グラフ化',
        # Text used to separate site title from page title
        separator: '-',
        # Site title - Page title
        reverse: true,
        # モバイル用 viewport
        viewport: 'width=device-width, initial-scale=1.0',
    }
  end
end
