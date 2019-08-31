class ExportController < ApplicationController
  before_action :authenticate

  def index
    set_meta_tags title: 'エクスポート'
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
    @ship_statuses = ShipStatus.where(admiral_id: current_admiral.id).
        order(:exported_at).order(:book_no).order(:remodel_level)

    respond_to do |format|
      format.csv do
        send_data render_to_string, filename: 'ship_statuses.csv', type: :csv
      end
    end
  end
end
