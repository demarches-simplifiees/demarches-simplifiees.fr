module ProcedureStatsConcern
  extend ActiveSupport::Concern

  NB_DAYS_RECENT_DOSSIERS = 30
  # Percentage of dossiers considered to compute the 'usual traitement time'.
  # For instance, a value of '90' means that the usual traitement time will return
  # the duration under which 90% of the given dossiers are closed.
  USUAL_TRAITEMENT_TIME_PERCENTILE = 90

  def stats_usual_traitement_time
    Rails.cache.fetch("#{cache_key_with_version}/stats_usual_traitement_time", expires_in: 12.hours) do
      usual_traitement_time_for_recent_dossiers(NB_DAYS_RECENT_DOSSIERS)
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

  def traitement_times(date_range)
    Traitement.for_traitement_time_stats(self)
      .where(processed_at: date_range)
      .pluck('dossiers.en_construction_at', :processed_at)
      .map { |en_construction_at, processed_at| { en_construction_at: en_construction_at, processed_at: processed_at } }
  end

  def usual_traitement_time_by_month_in_days
    traitement_times(first_processed_at..last_considered_processed_at)
      .group_by { |t| t[:processed_at].beginning_of_month }
      .transform_values { |month| month.map { |h| h[:processed_at] - h[:en_construction_at] } }
      .transform_values { |traitement_times_for_month| traitement_times_for_month.percentile(USUAL_TRAITEMENT_TIME_PERCENTILE).ceil }
      .transform_values { |seconds| seconds == 0 ? nil : seconds }
      .transform_values { |seconds| convert_seconds_in_days(seconds) }
      .transform_keys { |month| pretty_month(month) }
  end

  def usual_traitement_time_for_recent_dossiers(nb_days)
    now = Time.zone.now
    traitement_time =
      traitement_times((now - nb_days.days)..now)
        .map { |times| times[:processed_at] - times[:en_construction_at] }
        .percentile(USUAL_TRAITEMENT_TIME_PERCENTILE)
        .ceil

    traitement_time = nil if traitement_time == 0
    traitement_time
  end

  private

  def first_processed_at
    Traitement.for_traitement_time_stats(self).pick(:processed_at)
  end

  def last_considered_processed_at
    (Time.zone.now - 1.month).end_of_month
  end

  def convert_seconds_in_days(seconds)
    (seconds / 60.0 / 60.0 / 24.0).ceil
  end

  def pretty_month(month)
    I18n.l(month, format: "%B %Y")
  end
end
