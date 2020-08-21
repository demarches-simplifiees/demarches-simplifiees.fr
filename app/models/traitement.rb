# == Schema Information
#
# Table name: traitements
#
#  id                :bigint           not null, primary key
#  instructeur_email :string
#  motivation        :string
#  processed_at      :datetime
#  state             :string
#  dossier_id        :bigint
#
class Traitement < ApplicationRecord
  belongs_to :dossier

  scope :termine_close_to_expiration, -> do
    joins(dossier: :procedure)
      .where(state: Dossier::TERMINE)
      .where('dossiers.state' => Dossier::TERMINE)
      .where("traitements.processed_at + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: Dossier::INTERVAL_BEFORE_EXPIRATION })
  end
end
