# == Schema Information
#
# Table name: traitements
#
#  id                :bigint           not null, primary key
#  instructeur_email :string
#  motivation        :string
#  process_expired   :boolean
#  processed_at      :datetime
#  state             :string
#  dossier_id        :bigint
#
class Traitement < ApplicationRecord
  belongs_to :dossier, optional: false

  scope :termine_close_to_expiration, -> do
    joins(dossier: :procedure)
      .where(state: Dossier::TERMINE)
      .where(process_expired: true)
      .where('dossiers.state' => Dossier::TERMINE)
      .where("traitements.processed_at + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: Dossier::INTERVAL_BEFORE_EXPIRATION })
  end

  scope :for_traitement_time_stats, -> (procedure) do
    includes(:dossier)
      .where(dossier: procedure.dossiers)
      .where.not('dossiers.en_construction_at' => nil, :processed_at => nil)
      .order(:processed_at)
  end

  def self.count_dossiers_termines_by_month(groupe_instructeurs)
    last_traitements_per_dossier = Traitement
      .select('max(traitements.processed_at) as processed_at')
      .where(dossier: Dossier.state_termine.where(groupe_instructeur: groupe_instructeurs))
      .group(:dossier_id)
      .to_sql

    sql = <<~EOF
      select date_trunc('month', r1.processed_at::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'::INTERVAL) as month, count(r1.processed_at)
      from (#{last_traitements_per_dossier}) as r1
      group by date_trunc('month', r1.processed_at::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'::INTERVAL)
      order by month desc
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end

  def self.count_dossiers_termines_by_days_for_month(groupe_instructeurs, month)
    last_traitements_per_dossier = Traitement
      .select('max(traitements.processed_at) as processed_at')
      .where(processed_at: month.beginning_of_month..month.end_of_month, dossier: Dossier.state_termine.where(groupe_instructeur: groupe_instructeurs))
      .group(:dossier_id)
      .to_sql

    sql = <<~EOF
      select date_trunc('day', r1.processed_at::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'::INTERVAL) as day, count(r1.processed_at)
      from (#{last_traitements_per_dossier}) as r1
      group by date_trunc('day', r1.processed_at::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'::INTERVAL)
      order by day desc
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end

  def self.count_dossiers_termines_with_archive_size_limit(procedure, groupe_instructeurs, month)
    dossiers_termines_count_by_day = count_dossiers_termines_by_days_for_month(groupe_instructeurs, month).to_a
    result = []
    new_period = true
    start_day = dossiers_termines_count_by_day.first["day"]
    cumul_count = 0
    dossiers_termines_count_by_day.each do |dossiers|
      current_day = dossiers["day"]
      start_day = current_day if new_period
      cumul_count += dossiers["count"]
      if procedure.estimate_weight(cumul_count) >= Archive::MAX_WEIGHT || dossiers["day"] == dossiers_termines_count_by_day.last["day"]

        result << { start_day: start_day, end_day: dossiers["day"], count: cumul_count }
        cumul_count = 0
        new_period = true
      else
        new_period = false
      end
    end

    result
  end
end
