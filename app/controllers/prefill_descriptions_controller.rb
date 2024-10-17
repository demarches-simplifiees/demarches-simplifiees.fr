# frozen_string_literal: true

class PrefillDescriptionsController < ApplicationController
  before_action :retrieve_procedure
  before_action :set_prefill_description

  def edit
  end

  def update
    @prefill_description.update(prefill_description_params)

    respond_to do |format|
      format.turbo_stream
      format.html { render :edit }
    end
  end

  private

  def retrieve_procedure
    @procedure = Procedure.publiees_ou_brouillons.opendata.find_with_path(params[:path]).first!
  end

  def set_prefill_description
    @prefill_description = PrefillDescription.new(@procedure)
  end

  def prefill_description_params
    params.require(:procedure).permit(:selected_type_de_champ_ids, :identity_items_selected)
  end
end
