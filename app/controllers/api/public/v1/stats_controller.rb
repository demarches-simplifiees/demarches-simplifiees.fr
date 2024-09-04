# frozen_string_literal: true

class API::Public::V1::StatsController < API::Public::V1::BaseController
  before_action :retrieve_procedure

  def index
    render json: {
      funnel: @procedure.stats_dossiers_funnel.as_json,
      processed: @procedure.stats_termines_states.as_json,
      processed_by_week: @procedure.stats_termines_by_week.as_json,
      processing_time: @procedure.stats_usual_traitement_time.as_json,
      processing_time_by_month: @procedure.stats_usual_traitement_time_by_month_in_days.as_json
    }
  end

  private

  def retrieve_procedure
    @procedure = Procedure.opendata.find_by(id: params[:id])
    render_not_found("procedure", params[:id]) if @procedure.blank?
  end
end
