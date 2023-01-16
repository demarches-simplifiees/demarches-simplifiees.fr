class API::Public::V1::JSONSchemaProceduresController < API::Public::V1::BaseController
  skip_before_action :check_content_type_is_json
  before_action :retrieve_procedure
  before_action :set_prefill_description

  def show
    render json: PrefillDescriptionSerializer.new(@prefill_description).as_json, status: 200
  end

  private

  def retrieve_procedure
    @procedure = Procedure.publiees_ou_brouillons.opendata.find_by!(path: params[:path])
  end

  def set_prefill_description
    @prefill_description = PrefillDescription.new(@procedure)
  end
end
