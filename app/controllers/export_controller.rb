class ExportController < ApplicationController
  before_action :authenticate

  LIMIT = 100000

  def index
    set_meta_tags title: 'エクスポート'

    @admiral_status_count = AdmiralStatus.where(admiral_id: current_admiral.id).count
    @event_progress_status_count = EventProgressStatus.where(admiral_id: current_admiral.id).count
    @cop_event_progress_status_count = CopEventProgressStatus.where(admiral_id: current_admiral.id).count
    @ship_status_count = ShipStatus.where(admiral_id: current_admiral.id).count

    @ship_status_pages = (@ship_status_count.to_f / LIMIT).ceil
  end

  def admiral_statuses
    @admiral_statuses = AdmiralStatus.where(admiral_id: current_admiral.id).order(:exported_at)

    respond_to do |format|
      format.csv do
        send_data render_to_string, filename: 'admiral_statuses.csv', type: :csv
      end
    end
  end

  def event_progress_statuses
    @event_progress_statuses = EventProgressStatus.where(admiral_id: current_admiral.id).
        order(:exported_at).order(:event_no).order(:level).order(:period)

    respond_to do |format|
      format.csv do
        send_data render_to_string, filename: 'event_progress_statuses.csv', type: :csv
      end
    end
  end

  def cop_event_progress_statuses
    @cop_event_progress_statuses = CopEventProgressStatus.where(admiral_id: current_admiral.id).
        order(:exported_at).order(:event_no)

    respond_to do |format|
      format.csv do
        send_data render_to_string, filename: 'cop_event_progress_statuses.csv', type: :csv
      end
    end
  end

  def ship_statuses
    page = params[:page]

    if page
      offset = (page.to_i - 1) * LIMIT

      @ship_statuses = ShipStatus.where(admiral_id: current_admiral.id).
          order(:exported_at).order(:book_no).order(:remodel_level).limit(LIMIT).offset(offset)

      respond_to do |format|
        format.csv do
          send_data render_to_string, filename: "ship_statuses_#{page}.csv", type: :csv
        end
      end
    else
      @ship_statuses = ShipStatus.where(admiral_id: current_admiral.id).
          order(:exported_at).order(:book_no).order(:remodel_level).limit(LIMIT)

      respond_to do |format|
        format.csv do
          send_data render_to_string, filename: 'ship_statuses.csv', type: :csv
        end
      end
    end
  end
end
