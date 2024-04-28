# frozen_string_literal: true

class Dossiers::UserFilterComponent < ApplicationComponent
  include DossierHelper

  def initialize(statut:, filter:, procedure_id:)
    @statut = statut
    @filter = filter
    @procedure_id = procedure_id
  end

  attr_reader :statut, :filter, :procedure_id

  def render?
    ['en-cours', 'traites'].include?(@statut)
  end

  def states_collection(statut)
    case statut
    when 'en-cours'
      (Dossier.states.values - Dossier::TERMINE) << Dossier::A_CORRIGER
    when 'traites'
      Dossier::TERMINE
    end.map { |state| [t("activerecord.attributes.dossier/state.#{state}"), state] }
  end
end
