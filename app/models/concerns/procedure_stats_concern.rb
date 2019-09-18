module ProcedureStatsConcern
  extend ActiveSupport::Concern

  def stats_usual_traitement_time
    Rails.cache.fetch("#{cache_key_with_version}/stats_usual_traitement_time", expires_in: 12.hours) do
      usual_traitement_time
    end
  end

  def stats_dossiers_funnel
    Rails.cache.fetch("#{cache_key_with_version}/stats_dossiers_funnel", expires_in: 12.hours) do
      [
        ['Démarrés', dossiers.count],
        ['Déposés', dossiers.state_not_brouillon.count],
        ['Instruction débutée', dossiers.state_instruction_commencee.count],
        ['Traités', dossiers.state_termine.count]
      ]
    end
  end

  def stats_termines_states
    Rails.cache.fetch("#{cache_key_with_version}/stats_termines_states", expires_in: 12.hours) do
      [
        ['Acceptés', dossiers.where(state: :accepte).count],
        ['Refusés', dossiers.where(state: :refuse).count],
        ['Classés sans suite', dossiers.where(state: :sans_suite).count]
      ]
    end
  end
end
