class StatsController < ApplicationController
  layout "new_application"

  MEAN_NUMBER_OF_CHAMPS_IN_A_FORM = 24.0

  def index
    procedures = Procedure.where(:published => true)
    dossiers = Dossier.where.not(:state => :draft)

    @procedures_count = procedures.count
    @dossiers_count = dossiers.count

    @procedures_cumulative = cumulative_hash(procedures)
    @procedures_in_the_last_4_months = last_four_months_hash(procedures)

    @dossiers_cumulative = cumulative_hash(dossiers, :initiated_at)
    @dossiers_in_the_last_4_months = last_four_months_hash(dossiers, :initiated_at)

    @procedures_count_per_administrateur = procedures_count_per_administrateur(procedures)

    @dossier_instruction_mean_time = dossier_instruction_mean_time(dossiers)
    @dossier_filling_mean_time = dossier_filling_mean_time(dossiers)
  end

  private

  def last_four_months_hash(association, date_attribute = :created_at)
    min_date = 3.months.ago.beginning_of_month.to_date
    max_date = Time.now.to_date

     association
      .where(date_attribute => min_date..max_date)
      .group("DATE_TRUNC('month', #{date_attribute.to_s})")
      .count
      .to_a
      .sort{ |x, y| x[0] <=> y[0] }
      .map { |e| [I18n.l(e.first, format: "%B %Y"), e.last] }
  end

  def cumulative_hash(association, date_attribute = :created_at)
    sum = 0
    association
      .group("DATE_TRUNC('month', #{date_attribute.to_s})")
      .count
      .to_a
      .sort{ |x, y| x[0] <=> y[0] }
      .map { |x, y| { x => (sum += y)} }
      .reduce({}, :merge)
  end

  def procedures_count_per_administrateur(procedures)
    count_per_administrateur = procedures.group(:administrateur_id).count.values
    {
      'Une procédure' => count_per_administrateur.select { |count| count == 1 }.count,
      'Entre deux et cinq procédures' => count_per_administrateur.select { |count| 2 <= count && count <= 5  }.count,
      'Plus de cinq procédures' => count_per_administrateur.select { |count| 5 < count }.count
    }
  end

  def mean(collection)
    (collection.sum.to_f / collection.size).round(2)
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
      .pluck(:procedure_id, :initiated_at, :processed_at)

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
      .pluck(:procedure_id, :created_at, :initiated_at, :processed_at)

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
end
