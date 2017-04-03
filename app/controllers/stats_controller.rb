class StatsController < ApplicationController

  def index
    procedures = Procedure.where(:published => true)
    dossiers = Dossier.where.not(:state => :draft)

    @procedures_30_days_flow = thirty_days_flow_hash(procedures)
    @dossiers_30_days_flow = thirty_days_flow_hash(dossiers)

    @procedures_cumulative = cumulative_hash(procedures)
    @dossiers_cumulative = cumulative_hash(dossiers)

    @procedures_count = procedures.count
    @dossiers_count = dossiers.count
  end

  private

  def thirty_days_flow_hash(association)
    thirty_days_flow_hash = association
      .where(:created_at => 30.days.ago..Time.now)
      .group("date_trunc('day', created_at)")
      .count

    clean_hash(thirty_days_flow_hash)
  end

  def clean_hash h
    h.keys.each{ |key| h[key.to_date] = h[key]; h.delete(key) }
    min_date = h.keys.min
    max_date = h.keys.max
    (min_date..max_date).each do |date|
      h[date] = 0 if h[date].nil?
    end
    h
  end

  def cumulative_hash(association)
    sum = 0
    association
      .group("DATE_TRUNC('month', created_at)")
      .count
      .to_a
      .sort{ |x, y| x[0] <=> y[0] }
      .map { |x, y| { x => (sum += y)} }
      .reduce({}, :merge)
  end
end
