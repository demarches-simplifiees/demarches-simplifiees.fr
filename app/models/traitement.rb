# == Schema Information
#
# Table name: traitements
#
#  id                       :bigint           not null, primary key
#  instructeur_email        :string
#  motivation               :string
#  process_expired          :boolean
#  process_expired_migrated :boolean          default(FALSE)
#  processed_at             :datetime
#  state                    :string
#  dossier_id               :bigint
#
class Traitement < ApplicationRecord
  belongs_to :dossier, optional: false

  scope :en_construction, -> { where(state: Dossier.states.fetch(:en_construction)) }
  scope :en_instruction, -> { where(state: Dossier.states.fetch(:en_instruction)) }
  scope :termine, -> { where(state: Dossier::TERMINE) }

  scope :for_traitement_time_stats, -> (procedure) do
    includes(:dossier)
      .termine
      .where(dossier: procedure.dossiers)
      .where.not('dossiers.depose_at' => nil, processed_at: nil)
      .order(:processed_at)
  end

  scope :termine_close_to_expiration, -> do
    joins(dossier: :procedure)
      .termine
      .where(process_expired: true)
      .where('dossiers.state' => Dossier::TERMINE)
      .where("traitements.processed_at + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: Dossier::INTERVAL_BEFORE_EXPIRATION })
  end

end
