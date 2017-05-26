class StatsController < ApplicationController
  layout "new_application"

  def index
    procedures = Procedure.where(:published => true)
    dossiers = Dossier.where.not(:state => :draft)

    @procedures_in_the_last_4_months = last_four_months_hash(procedures)
    @dossiers_in_the_last_4_months = last_four_months_hash(dossiers, :initiated_at)

    @procedures_30_days_flow = thirty_days_flow_hash(procedures)
    @dossiers_30_days_flow = thirty_days_flow_hash(dossiers, :initiated_at)

    @procedures_cumulative = cumulative_hash(procedures)
    @dossiers_cumulative = cumulative_hash(dossiers, :initiated_at)

    @procedures_count = procedures.count
    @dossiers_count = dossiers.count
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

  def thirty_days_flow_hash(association, date_attribute = :created_at)
    min_date = 30.days.ago.to_date
    max_date = Time.now.to_date

    thirty_days_flow_hash = association
      .where(date_attribute => min_date..max_date)
      .group("date_trunc('day', #{date_attribute.to_s})")
      .count

    clean_hash(thirty_days_flow_hash, min_date, max_date)
  end

  def clean_hash(h, min_date, max_date)
    # Convert keys to date
    h = Hash[h.map { |(k, v)| [k.to_date, v] }]

    # Add missing vales where count is 0
    (min_date..max_date).each do |date|
      if h[date].nil?
        h[date] = 0
      end
    end

    h
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

end
