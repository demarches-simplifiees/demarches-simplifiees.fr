class DossierRebaseJob < ApplicationJob
  # If by the time the job runs the Dossier has been deleted, ignore the rebase
  discard_on ActiveRecord::RecordNotFound

  def perform(dossier)
    dossier.rebase!
  end
end
