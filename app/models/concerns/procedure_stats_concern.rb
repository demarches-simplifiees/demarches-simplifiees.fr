module ProcedureStatsConcern
  extend ActiveSupport::Concern

  def stats_usual_traitement_time
    Rails.cache.fetch("#{cache_key_with_version}/stats_usual_traitement_time", expires_in: 12.hours) do
      usual_traitement_time
    end
  end

  def stats_usual_traitement_time_by_month_in_days
    Rails.cache.fetch("#{cache_key_with_version}/stats_usual_traitement_time_by_month_in_days", expires_in: 12.hours) do
      usual_traitement_time_by_month_in_days
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

  def stats_termines_by_week
    Rails.cache.fetch("#{cache_key_with_version}/stats_termines_by_week", expires_in: 12.hours) do
      now = Time.zone.now
      chart_data = dossiers.includes(:traitements)
        .state_termine
        .where(traitements: { processed_at: (now.beginning_of_week - 6.months)..now.end_of_week })

      dossier_state_values = chart_data.pluck(:state).sort.uniq

      # rubocop:disable Style/HashTransformValues
      dossier_state_values
        .map do |state|
          { name: state, data: chart_data.where(state: state).group_by_week { |dossier| dossier.traitements.first.processed_at }.map { |k, v| [k, v.count] }.to_h }
          # rubocop:enable Style/HashTransformValues
        end
    end
  end

  def usual_traitement_time
    compute_usual_traitement_time_for_month(Time.zone.now)
  end

  def compute_usual_traitement_time_for_month(month_date)
    times = Traitement.includes(:dossier)
      .where(dossier: self.dossiers)
      .where.not('dossiers.en_construction_at' => nil, :processed_at => nil)
      .where(processed_at: (month_date - 1.month)..month_date)
      .pluck('dossiers.en_construction_at', :processed_at)
      .map { |(en_construction_at, processed_at)| processed_at - en_construction_at }

    if times.present?
      times.percentile(90).ceil
    end
  end

  def usual_traitement_time_by_month
    first_processed_at = Traitement.includes(:dossier)
      .where(dossier: self.dossiers)
      .where.not('dossiers.en_construction_at' => nil, :processed_at => nil)
      .order(:processed_at)
      .pick(:processed_at)

    return [] if first_processed_at.nil?
    month_index = first_processed_at.at_end_of_month
    month_range = []
    while month_index <= Time.zone.now.at_end_of_month
      month_range << month_index
      month_index += 1.month
    end

    month_range.map do |month|
      [I18n.l(month, format: "%B %Y"), compute_usual_traitement_time_for_month(month)]
    end
  end

  def usual_traitement_time_by_month_in_days
    usual_traitement_time_by_month.map do |month, time_in_seconds|
      if time_in_seconds.present?
        time_in_days = (time_in_seconds / 60.0 / 60.0 / 24.0).ceil
      else
        time_in_days = nil
      end
      [month, time_in_days]
    end
  end

end
