class ImportController < ApplicationController
  include Import

  before_action :authenticate

  def index
    set_meta_tags title: 'インポート'
    @tokens = AdmiralToken.where('admiral_id = ?', current_admiral.id).order(issued_at: :asc)
  end

  # ファイルのアップロード
  def file
    set_meta_tags title: 'インポート'
    @tokens = AdmiralToken.where('admiral_id = ?', current_admiral.id).order(issued_at: :asc)

    # エラーが発生した場合のみ、エラーメッセージが格納される変数
    @error = nil

    # 成功、または成功でも失敗でもないメッセージ
    # flash は上限が 4KB なので、すべてのメッセージを格納できない。
    # そのため、flash[:messages] を使う方式から、変数 @messages を使う方式に変更した。
    @messages = []

    files = params[:files]

    if files.blank?
      @error = 'ファイルが指定されていません。'
      render :action => :index
      return
    end

    if params[:file_type].nil?
      @error = '種別が指定されていません。'
      render :action => :index
      return
    end

    # タイムスタンプを取得できるか検査
    timestamps = {}
    files.each do |file|
      # ファイル名からタイムスタンプを取得
      file_name = file.original_filename
      if file_name =~ /(\d{8}_\d{6})/
        timestamps[file] = parse_time($1)
        logger.debug('exported_at: ' + timestamps[file].to_s)
      else
        @error = "タイムスタンプが指定されていません。（ファイル名：#{file_name}）"
        render :action => :index
        return
      end
    end

    files.each do |file|
      # ファイル名の自動判別と、ログ出力のためにファイル名を取得
      file_name = file.original_filename

      # エクスポート時刻から API version を推測
      exported_at = timestamps[file]
      api_version = AdmiralStatsParser.guess_api_version(exported_at)

      json = file.read

      case params[:file_type]
        when 'basic_info', 'ship_book', 'ship_list', 'event_info', 'blueprint_list'
          file_type = params[:file_type].to_sym
        else
          # file_type が未知（'auto' 含む）の場合は、ファイル名からファイル種別の自動判別を行う
          case file_name
            when /^Personal_basicInfo_/
              file_type = :basic_info
            when /^TcBook_info_/
              file_type = :ship_book
            when /^CharacterList_info_/
              file_type = :ship_list
            when /^Event_info_/
              file_type = :event_info
            when /^BlueprintList_info_/
              file_type = :blueprint_list
            else
              @messages << "ファイル種別を自動判別できなかったため、無視されました。（ファイル名：#{file_name}）"
              next
          end
      end

      res, msg = case file_type
                   when :basic_info
                     save_admiral_statuses(current_admiral.id, exported_at, json, api_version)
                   when :ship_book
                     save_ship_cards(current_admiral.id, exported_at, json, api_version)
                   when :ship_list
                     save_ship_statuses(current_admiral.id, exported_at, json, api_version)
                   when :event_info
                     save_event_progress_statuses(current_admiral.id, exported_at, json, api_version)
                   when :blueprint_list
                     save_blueprint_statuses(current_admiral.id, exported_at, json, api_version)
                 end

      case res
        when :ok, :created
          @messages << msg + "（ファイル名：#{file_name}）"
        else
          @error = msg + "（ファイル名：#{file_name}）"
          break
      end
    end

    render :action => :index
  end
end
