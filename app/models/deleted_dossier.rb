class DeletedDossier < ApplicationRecord
  belongs_to :procedure

  scope :for_dossier, -> (dossier_id) { where(dossier_id: dossier_id) }

  def self.create_from_dossier(dossier)
    DeletedDossier.create!(dossier_id: dossier.id, procedure: dossier.procedure, state: dossier.state, deleted_at: Time.zone.now)
  end
end
