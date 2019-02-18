class DeletedDossier < ApplicationRecord
  belongs_to :procedure

  def self.create_from_dossier(dossier)
    DeletedDossier.create!(dossier_id: dossier.id, procedure: dossier.procedure, state: dossier.state, deleted_at: Time.now.utc)
  end
end
