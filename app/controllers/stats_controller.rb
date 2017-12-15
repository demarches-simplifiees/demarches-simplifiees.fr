class StatsController < ApplicationController
  layout "new_application"

  MEAN_NUMBER_OF_CHAMPS_IN_A_FORM = 24.0

  def index
    procedures = Procedure.publiees_ou_archivees
    dossiers = Dossier.where.not(:state => :brouillon)

    @procedures_count = procedures.count
    @dossiers_count = dossiers.count

    @procedures_cumulative = cumulative_hash(procedures, :published_at)
    @procedures_in_the_last_4_months = last_four_months_hash(procedures, :published_at)

    @dossiers_cumulative = cumulative_hash(dossiers, :en_construction_at)
    @dossiers_in_the_last_4_months = last_four_months_hash(dossiers, :en_construction_at)

    @procedures_count_per_administrateur = procedures_count_per_administrateur(procedures)

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
  end

  private

  def max_date
    if administration_signed_in?
      Time.now.to_date
    else
      Time.now.beginning_of_month - 1.second
    end
  end

  def last_four_months_hash(association, date_attribute)
    min_date = 3.months.ago.beginning_of_month.to_date

     association
      .where(date_attribute => min_date..max_date)
      .group("DATE_TRUNC('month', #{date_attribute.to_s})")
      .count
      .to_a
      .sort_by { |a| a[0] }
      .map { |e| [I18n.l(e.first, format: "%B %Y"), e.last] }
  end

  def cumulative_hash(association, date_attribute)
    sum = 0
    association
      .where("#{date_attribute.to_s} < ?", max_date)
      .group("DATE_TRUNC('month', #{date_attribute.to_s})")
      .count
      .to_a
      .sort_by { |a| a[0] }
      .map { |x, y| { x => (sum += y)} }
      .reduce({}, :merge)
  end

  def procedures_count_per_administrateur(procedures)
    count_per_administrateur = procedures.group(:administrateur_id).count.values
    {
      'Une procédure' => count_per_administrateur.select { |count| count == 1 }.count,
      'Entre deux et cinq procédures' => count_per_administrateur.select { |count| 2 <= count && count <= 5 }.count,
      'Plus de cinq procédures' => count_per_administrateur.select { |count| 5 < count }.count
    }
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
    max_date = Time.now.to_date

    processed_dossiers = dossiers
      .where(:processed_at => min_date..max_date)
      .pluck(:procedure_id, :en_construction_at, :processed_at)

    # Group dossiers by month
    processed_dossiers_by_month = processed_dossiers
      .group_by do |dossier|
        dossier[2].beginning_of_month.to_s
      end

    processed_dossiers_by_month.map do |month, value|
      # Group the dossiers for this month by procedure
      dossiers_grouped_by_procedure = value.group_by { |dossier| dossier[0] }

      # Compute the mean time for this procedure
      procedure_processing_times = dossiers_grouped_by_procedure.map do |procedure_id, procedure_dossiers|
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
    max_date = Time.now.to_date

    processed_dossiers = dossiers
      .where(:processed_at => min_date..max_date)
      .pluck(:procedure_id, :created_at, :en_construction_at, :processed_at)

    # Group dossiers by month
    processed_dossiers_by_month = processed_dossiers
      .group_by do |e|
        e[3].beginning_of_month.to_s
      end

    processed_dossiers_by_month.map do |month, value|
      # Group the dossiers for this month by procedure
      dossiers_grouped_by_procedure = value.group_by { |dossier| dossier[0] }

      # Compute the mean time for this procedure
      procedure_processing_times = dossiers_grouped_by_procedure.map do |procedure_id, procedure_dossiers|
        procedure_dossiers_processing_time = procedure_dossiers.map do |dossier|
          (dossier[2] - dossier[1]).to_f / 60
        end

        procedure_mean = mean(procedure_dossiers_processing_time)

        # We normalize the data for 24 fields
        procedure_fields_count = Procedure.find(procedure_id).types_de_champ.count
        procedure_mean * (MEAN_NUMBER_OF_CHAMPS_IN_A_FORM / procedure_fields_count)
      end

      # Compute the average mean time for all the procedures of this month
      month_average = mean(procedure_processing_times)

      [month, month_average]
    end.to_h
  end

  def avis_usage
    [3.week.ago, 2.week.ago, 1.week.ago].map do |min_date|
      max_date = min_date + 1.week

      weekly_dossiers = Dossier.includes(:avis).where(created_at: min_date..max_date).to_a

      weekly_dossiers_count = weekly_dossiers.count

      if weekly_dossiers_count == 0
        result = 0
      else
        weekly_dossier_with_avis_count = weekly_dossiers.select { |dossier| dossier.avis.present? }.count
        result = percentage(weekly_dossier_with_avis_count, weekly_dossiers_count)
      end

      [min_date.to_i, result]
    end
  end

  def avis_average_answer_time
    [3.week.ago, 2.week.ago, 1.week.ago].map do |min_date|
      max_date = min_date + 1.week

      average = Avis.with_answer
        .where(created_at: min_date..max_date)
        .average("EXTRACT(EPOCH FROM avis.updated_at - avis.created_at) / 86400")

      result = average ? average.to_f.round(2) : 0

      [min_date.to_i, result]
    end
  end

  def avis_answer_percentages
    [3.week.ago, 2.week.ago, 1.week.ago].map do |min_date|
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
    [3.week.ago, 2.week.ago, 1.week.ago].map do |date|
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
    [3.week.ago, 2.week.ago, 1.week.ago].map do |date|
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
