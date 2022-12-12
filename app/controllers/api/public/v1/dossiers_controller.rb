class API::Public::V1::DossiersController < API::Public::V1::BaseController
  before_action :check_procedure_id_presence
  before_action :retreive_procedure

  def create
  end

  private

  def check_procedure_id_presence
    render_missing_param(:procedure_id) if params[:procedure_id].blank?
  end

  def retreive_procedure
    @procedure = Procedure.publiees_ou_brouillons.opendata.find_by(id: params[:procedure_id])
    render_not_found("procedure", params[:procedure_id]) if @procedure.blank?
  end
end
