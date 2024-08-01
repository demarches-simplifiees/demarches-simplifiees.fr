# frozen_string_literal: true

class ProcedureSVASVRProcessDossierJob < ApplicationJob
  queue_as :sva

  def perform(dossier)
    dossier.process_sva_svr!
  end
end
