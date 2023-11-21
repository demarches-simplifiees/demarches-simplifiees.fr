class Procedure::EstimatedDelayComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
    @fastest, @mean, @slow = procedure.usual_traitement_time_for_recent_dossiers(ProcedureStatsConcern::NB_DAYS_RECENT_DOSSIERS)
  end

  def estimation_present?
    @fastest && @mean && @slow
  end

  def render?
    estimation_present?
  end
end
