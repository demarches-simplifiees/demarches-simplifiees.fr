class DescriptionsController < ApplicationController
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

  def set_description
    @description = Description.new(Procedure.publiees.or(Procedure.brouillons).opendata.find_by!(path: params[:path]))
  end

  def description_params
    params.require(:procedure).permit(
      :type_de_champ_id_to_add,
      :type_de_champ_id_to_remove,
      type_de_champ_ids: []
    )
  end
end
