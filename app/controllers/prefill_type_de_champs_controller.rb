# frozen_string_literal: true

class PrefillTypeDeChampsController < ApplicationController
  before_action :retrieve_procedure
  before_action :set_prefill_type_de_champ

  def show
  end

  private

  def retrieve_procedure
    @procedure = Procedure.publiees_ou_brouillons.opendata.find_by!(path: params[:path])
  end

  def set_prefill_type_de_champ
    @type_de_champ = TypesDeChamp::PrefillTypeDeChamp.build(@procedure.active_revision.types_de_champ.fillable.find(params[:id]), @procedure.active_revision)
  end
end
