module Users
  class StatistiquesController < ApplicationController
    def statistiques
      @procedure = procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

      @usual_traitement_time = @procedure.stats_usual_traitement_time
      @dossiers_funnel = @procedure.stats_dossiers_funnel
      @termines_states = @procedure.stats_termines_states
      @termines_by_week = @procedure.stats_termines_by_week

      render :show
    end

    private

    def procedure
      Procedure.publiees.or(Procedure.brouillons).find_by(path: params[:path])
    end
  end
end
