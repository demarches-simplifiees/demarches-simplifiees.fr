class StatsController < ApplicationController
  before_action :authenticate_super_admin!, only: [:download]

  MEAN_NUMBER_OF_CHAMPS_IN_A_FORM = 24.0

  def index
    stat = Stat.first

    procedures = Procedure.publiees_ou_closes

    @procedures_numbers = procedures_numbers(procedures)

    @dossiers_numbers = dossiers_numbers(
      stat.dossiers_not_brouillon,
      stat.dossiers_depose_avant_30_jours,
      stat.dossiers_deposes_entre_60_et_30_jours
    )

    @contact_percentage = Rails.cache.fetch("stats.contact_percentage", expires_in: 1.day) do
      contact_percentage
    end

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
          Arel.sql("dossiers.depose_at - dossiers.created_at"),
          Arel.sql("dossiers.en_instruction_at - dossiers.depose_at"),
          Arel.sql("dossiers.processed_at - dossiers.en_instruction_at")
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

  def contact_percentage
    number_of_months = 13

    from = Time.zone.today.prev_month(number_of_months)
    to = Time.zone.today.prev_month

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

        dossiers_count = Dossier.where(depose_at: start_date..end_date).count

        monthly_contact_percentage = replies_count.fdiv(dossiers_count || 1) * 100
        [I18n.l(start_date, format: '%b %y'), monthly_contact_percentage.round(1)]
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
end
