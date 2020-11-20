class StatsController < ApplicationController
  before_action :authenticate_super_admin!, only: [:download]

  MEAN_NUMBER_OF_CHAMPS_IN_A_FORM = 24.0

  def index
    stat = Stat.first

    procedures = Procedure.publiees_ou_closes
    dossiers = Dossier.state_not_brouillon

    @procedures_numbers = procedures_numbers(procedures)

    @dossiers_numbers = dossiers_numbers(
      stat.dossiers_not_brouillon,
      stat.dossiers_depose_avant_30_jours,
      stat.dossiers_deposes_entre_60_et_30_jours
    )

    @satisfaction_usagers = satisfaction_usagers

    @contact_percentage = contact_percentage

    @dossiers_states_for_pie = {
      "Brouillon" => stat.dossiers_brouillon,
      "En construction" => stat.dossiers_en_construction,
      "En instruction" => stat.dossiers_en_instruction,
      "Terminé" => stat.dossiers_termines
    }

    @procedures_cumulative = cumulative_hash(procedures, :published_at)
    @procedures_in_the_last_4_months = last_four_months_hash(procedures, :published_at)

    @dossiers_cumulative = stat.dossiers_cumulative
    @dossiers_in_the_last_4_months = stat.dossiers_in_the_last_4_months

    if super_admin_signed_in?
      @dossier_instruction_mean_time = Rails.cache.fetch("dossier_instruction_mean_time", expires_in: 1.day) do
        dossier_instruction_mean_time(dossiers)
      end

      @dossier_filling_mean_time = Rails.cache.fetch("dossier_filling_mean_time", expires_in: 1.day) do
        dossier_filling_mean_time(dossiers)
      end

      @avis_usage = avis_usage
      @avis_average_answer_time = avis_average_answer_time
      @avis_answer_percentages = avis_answer_percentages

      @motivation_usage_dossier = motivation_usage_dossier
      @motivation_usage_procedure = motivation_usage_procedure

      @cloned_from_library_procedures_ratio = cloned_from_library_procedures_ratio
    end
  end

  def download
    headers = [
      'ID du dossier',
      'ID de la démarche',
      'Nom de la démarche',
      'ID utilisateur',
      'Etat du fichier',
      'Durée en brouillon',
      'Durée en construction',
      'Durée en instruction'
    ]

    data = Dossier
      .includes(:procedure, :user)
      .in_batches
      .flat_map do |dossiers|
      dossiers
        .pluck(
          "dossiers.id",
          "procedures.id",
          "procedures.libelle",
          "users.id",
          "dossiers.state",
          "dossiers.en_construction_at - dossiers.created_at",
          "dossiers.en_instruction_at - dossiers.en_construction_at",
          "dossiers.processed_at - dossiers.en_instruction_at"
        )
    end

    respond_to do |format|
      format.csv { send_data(SpreadsheetArchitect.to_xlsx(headers: headers, data: data), filename: "statistiques.csv") }
    end
  end

  private

  def procedures_numbers(procedures)
    total = procedures.count
    last_30_days_count = procedures.where(published_at: 1.month.ago..Time.zone.now).count
    previous_count = procedures.where(published_at: 2.months.ago..1.month.ago).count
    if previous_count != 0
      evolution = (((last_30_days_count.to_f / previous_count) - 1) * 100).round(0)
    else
      evolution = 0
    end
    formatted_evolution = format("%+d", evolution)

    {
      total: total.to_s,
      last_30_days_count: last_30_days_count.to_s,
      evolution: formatted_evolution
    }
  end

  def dossiers_numbers(total, last_30_days_count, previous_count)
    if previous_count != 0
      evolution = (((last_30_days_count.to_f / previous_count) - 1) * 100).round(0)
    else
      evolution = 0
    end
    formatted_evolution = format("%+d", evolution)

    {
      total: total.to_s,
      last_30_days_count: last_30_days_count.to_s,
      evolution: formatted_evolution
    }
  end

  def satisfaction_usagers
    legend = {
      Feedback.ratings.fetch(:unhappy) => "Mécontents",
      Feedback.ratings.fetch(:neutral) => "Neutres",
      Feedback.ratings.fetch(:happy)   => "Satisfaits"
    }

    number_of_weeks = 12
    totals = Feedback
      .group_by_week(:created_at, last: number_of_weeks, current: false)
      .count

    legend.keys.map do |rating|
      data = Feedback
        .where(rating: rating)
        .group_by_week(:created_at, last: number_of_weeks, current: false)
        .count
        .map do |week, count|
          total = totals[week]
          # By default a week is displayed by the first day of the week – but we'd rather display the last day
          label = week.next_week

          if total > 0
            [label, (count.to_f / total * 100).round(2)]
          else
            [label, 0]
          end
        end.to_h

      {
        name: legend[rating],
        data: data
      }
    end
  end

  def contact_percentage
    number_of_months = 13

    from = Time.zone.now.prev_month(number_of_months)
    to = Time.zone.now.prev_month

    adapter = Helpscout::UserConversationsAdapter.new(from, to)
    if !adapter.can_fetch_reports?
      return nil
    end

    adapter
      .reports
      .map do |monthly_report|
        start_date = monthly_report[:start_date].to_time.localtime
        end_date = monthly_report[:end_date].to_time.localtime
        replies_count = monthly_report[:replies_sent]

        dossiers_count = Dossier.where(en_construction_at: start_date..end_date).count

        monthly_contact_percentage = replies_count.fdiv(dossiers_count || 1) * 100
        [I18n.l(start_date, format: '%b %y'), monthly_contact_percentage.round(1)]
      end
  end

  def cloned_from_library_procedures_ratio
    [3.weeks.ago, 2.weeks.ago, 1.week.ago].map do |date|
      min_date = date.beginning_of_week
      max_date = min_date.end_of_week

      all_procedures = Procedure.created_during(min_date..max_date)
      cloned_from_library_procedures = all_procedures.cloned_from_library

      denominator = [1, all_procedures.count].max

      ratio = percentage(cloned_from_library_procedures.count, denominator)

      [l(max_date, format: '%d/%m/%Y'), ratio]
    end
  end

  def max_date
    if super_admin_signed_in?
      Time.zone.now
    else
      Time.zone.now.beginning_of_month - 1.second
    end
  end

  def last_four_months_hash(association, date_attribute)
    min_date = 3.months.ago.beginning_of_month.to_date

    association
      .where(date_attribute => min_date..max_date)
      .group("DATE_TRUNC('month', #{date_attribute})")
      .count
      .to_a
      .sort_by { |a| a[0] }
      .map { |e| [I18n.l(e.first, format: "%B %Y"), e.last] }
  end

  def cumulative_hash(association, date_attribute)
    sum = 0
    association
      .where("#{date_attribute} < ?", max_date)
      .group("DATE_TRUNC('month', #{date_attribute})")
      .count
      .to_a
      .sort_by { |a| a[0] }
      .map { |x, y| { x => (sum += y) } }
      .reduce({}, :merge)
  end

  def mean(collection)
    (collection.sum.to_f / collection.size).round(2)
  end

  def percentage(numerator, denominator)
    ((numerator.to_f / denominator) * 100).round(2)
  end

  def dossier_instruction_mean_time(dossiers)
    # In the 12 last months, we compute for each month
    # the average time it took to instruct a dossier
    # We compute monthly averages by first making an average per procedure
    # and then computing the average for all the procedures

    min_date = 11.months.ago
    max_date = Time.zone.now.to_date

    processed_dossiers = Traitement.includes(:dossier)
      .where(dossier_id: dossiers)
      .where('dossiers.state' => Dossier::TERMINE)
      .where(:processed_at => min_date..max_date)
      .pluck('dossiers.groupe_instructeur_id', 'dossiers.en_construction_at', :processed_at)

    # Group dossiers by month
    processed_dossiers_by_month = processed_dossiers
      .group_by do |dossier|
        dossier[2].beginning_of_month.to_s
      end

    processed_dossiers_by_month.map do |month, value|
      # Group the dossiers for this month by procedure
      dossiers_grouped_by_groupe_instructeur = value.group_by { |dossier| dossier[0] }

      # Compute the mean time for this procedure
      procedure_processing_times = dossiers_grouped_by_groupe_instructeur.map do |_procedure_id, procedure_dossiers|
        procedure_dossiers_processing_time = procedure_dossiers.map do |dossier|
          (dossier[2] - dossier[1]).to_f / (3600 * 24)
        end

        mean(procedure_dossiers_processing_time)
      end

      # Compute the average mean time for all the procedures of this month
      month_average = mean(procedure_processing_times)

      [month, month_average]
    end.to_h
  end

  def dossier_filling_mean_time(dossiers)
    # In the 12 last months, we compute for each month
    # the average time it took to fill a dossier
    # We compute monthly averages by first making an average per procedure
    # and then computing the average for all the procedures
    # For each procedure, we normalize the data: the time is calculated
    # for a 24 champs form (the current form mean length)

    min_date = 11.months.ago
    max_date = Time.zone.now.to_date

    processed_dossiers = Traitement.includes(:dossier)
      .where(dossier: dossiers)
      .where('dossiers.state' => Dossier::TERMINE)
      .where(:processed_at => min_date..max_date)
      .pluck(
        'dossiers.groupe_instructeur_id',
        Arel.sql('EXTRACT(EPOCH FROM (dossiers.en_construction_at - dossiers.created_at)) / 60 AS processing_time'),
        :processed_at
      )

    # Group dossiers by month
    processed_dossiers_by_month = processed_dossiers
      .group_by do |(*_, processed_at)|
        processed_at.beginning_of_month.to_s
      end

    groupe_instructeur_ids = processed_dossiers.map { |gid, _, _| gid }.uniq
    groupe_instructeurs = GroupeInstructeur.where(id: groupe_instructeur_ids).pluck(:id, :procedure_id)

    procedure_id_type_de_champs_count = TypeDeChamp
      .where(private: false)
      .joins(:revision)
      .group('procedure_revisions.procedure_id')
      .count

    groupe_instructeur_id_type_de_champs_count = groupe_instructeurs.reduce({}) do |acc, (gi_id, procedure_id)|
      acc[gi_id] = procedure_id_type_de_champs_count[procedure_id]
      acc
    end

    processed_dossiers_by_month.map do |month, dossier_plucks|
      # Group the dossiers for this month by procedure
      dossiers_grouped_by_groupe_instructeur = dossier_plucks.group_by { |(groupe_instructeur_id, *_)| groupe_instructeur_id }

      # Compute the mean time for this procedure
      procedure_processing_times = dossiers_grouped_by_groupe_instructeur.map do |groupe_instructeur_id, procedure_dossiers|
        procedure_fields_count = groupe_instructeur_id_type_de_champs_count[groupe_instructeur_id]

        if (procedure_fields_count == 0 || procedure_fields_count.nil?)
          next
        end

        procedure_dossiers_processing_time = procedure_dossiers.map { |_, processing_time, _| processing_time }
        procedure_mean = mean(procedure_dossiers_processing_time)

        # We normalize the data for 24 fields
        procedure_mean * (MEAN_NUMBER_OF_CHAMPS_IN_A_FORM / procedure_fields_count)
      end
        .compact

      # Compute the average mean time for all the procedures of this month
      month_average = mean(procedure_processing_times)

      [month, month_average]
    end.to_h
  end

  def avis_usage
    [3.weeks.ago, 2.weeks.ago, 1.week.ago].map do |min_date|
      max_date = min_date + 1.week

      weekly_dossiers = Dossier.includes(:avis).where(created_at: min_date..max_date).to_a

      weekly_dossiers_count = weekly_dossiers.count

      if weekly_dossiers_count == 0
        result = 0
      else
        weekly_dossier_with_avis_count = weekly_dossiers.count { |dossier| dossier.avis.present? }
        result = percentage(weekly_dossier_with_avis_count, weekly_dossiers_count)
      end

      [min_date.to_i, result]
    end
  end

  def avis_average_answer_time
    [3.weeks.ago, 2.weeks.ago, 1.week.ago].map do |min_date|
      max_date = min_date + 1.week

      average = Avis.with_answer
        .where(created_at: min_date..max_date)
        .average("EXTRACT(EPOCH FROM avis.updated_at - avis.created_at) / 86400")

      result = average ? average.to_f.round(2) : 0

      [min_date.to_i, result]
    end
  end

  def avis_answer_percentages
    [3.weeks.ago, 2.weeks.ago, 1.week.ago].map do |min_date|
      max_date = min_date + 1.week

      weekly_avis = Avis.where(created_at: min_date..max_date)

      weekly_avis_count = weekly_avis.count

      if weekly_avis_count == 0
        [min_date.to_i, 0]
      else
        answered_weekly_avis_count = weekly_avis.with_answer.count
        result = percentage(answered_weekly_avis_count, weekly_avis_count)

        [min_date.to_i, result]
      end
    end
  end

  def motivation_usage_dossier
    [3.weeks.ago, 2.weeks.ago, 1.week.ago].map do |date|
      min_date = date.beginning_of_week
      max_date = date.end_of_week

      weekly_termine_dossiers = Dossier.where(processed_at: min_date..max_date)
      weekly_termine_dossiers_count = weekly_termine_dossiers.count
      weekly_termine_dossiers_with_motivation_count = weekly_termine_dossiers.where.not(motivation: nil).count

      if weekly_termine_dossiers_count == 0
        result = 0
      else
        result = percentage(weekly_termine_dossiers_with_motivation_count, weekly_termine_dossiers_count)
      end

      [l(max_date, format: '%d/%m/%Y'), result]
    end
  end

  def motivation_usage_procedure
    [3.weeks.ago, 2.weeks.ago, 1.week.ago].map do |date|
      min_date = date.beginning_of_week
      max_date = date.end_of_week

      procedures_with_dossier_processed_this_week = Procedure
        .joins(:dossiers)
        .where(dossiers: { processed_at: min_date..max_date })

      procedures_with_dossier_processed_this_week_count = procedures_with_dossier_processed_this_week
        .uniq
        .count

      procedures_with_dossier_processed_this_week_and_with_motivation_count = procedures_with_dossier_processed_this_week
        .where
        .not(dossiers: { motivation: nil })
        .uniq
        .count

      if procedures_with_dossier_processed_this_week_count == 0
        result = 0
      else
        result = percentage(procedures_with_dossier_processed_this_week_and_with_motivation_count, procedures_with_dossier_processed_this_week_count)
      end

      [l(max_date, format: '%d/%m/%Y'), result]
    end
  end
end
