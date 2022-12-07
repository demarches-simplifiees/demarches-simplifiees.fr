class DescriptionsController < ApplicationController
  before_action :retreive_procedure
  before_action :set_description

  def edit
  end

  def update
    @description.update(description_params)

    respond_to do |format|
      format.turbo_stream
      format.html { render :edit }
    end
  end

  private

  def retreive_procedure
    @procedure = Procedure.publiees_ou_brouillons.opendata.find_by!(path: params[:path])
  end

  def set_description
    @description = Description.new(@procedure)
  end

  def description_params
    params.require(:procedure).permit(
      :type_de_champ_id_to_add,
      :type_de_champ_id_to_remove,
      type_de_champ_ids: []
    )
  end
end
