# frozen_string_literal: true

class ProcedureSVASVRProcessDossierJob < ApplicationJob
  queue_as :critical

  def perform(dossier)
    dossier.process_sva_svr!
  end
end
