class PrefillingsController < ApplicationController
  before_action :retreive_procedure
  before_action :set_prefilling

  def edit
  end

  def update
    @prefilling.update(prefilling_params)

    respond_to do |format|
      format.turbo_stream
      format.html { render :edit }
    end
  end

  private

  def retreive_procedure
    @procedure = Procedure.publiees_ou_brouillons.opendata.find_by!(path: params[:path])
  end

  def set_prefilling
    @prefilling = Prefilling.new(@procedure)
  end

  def prefilling_params
    params.require(:procedure).permit(selected_type_de_champ_ids: [])
  rescue ActionController::ParameterMissing
    { selected_type_de_champ_ids: [] }
  end
end
