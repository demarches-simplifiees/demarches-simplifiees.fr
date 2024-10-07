class Instructeurs::DossiersNavigationComponent < ApplicationComponent
  attr_reader :dossier

  def initialize(dossier:, current_instructeur:)
    @dossier = dossier
    @cache = Cache::ShowProcedureLastState.new(current_instructeur: current_instructeur, procedure: dossier.procedure)
  end

  def last_state_opts
    @cache.fetch_last_state
  end

  def has_next?
    @cache.next_dossier_id(from_id: dossier.id).present?
  end

  def has_previous?
    @cache.previous_dossier_id(from_id: dossier.id).present?
  end
end
