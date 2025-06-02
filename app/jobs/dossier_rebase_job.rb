# frozen_string_literal: true

class DossierRebaseJob < ApplicationJob
  queue_as :low_priority # they are massively enqueued, so don't interfere with others especially antivirus

  # If by the time the job runs the Dossier has been deleted, ignore the rebase
  discard_on ActiveRecord::RecordNotFound

  def perform(dossier)
    dossier.rebase!
  end
end
