# frozen_string_literal: true

class EtablissementUpdateJob < ApplicationJob
  queue_as :critical # reporting will be done asap, but no occurence found. maube dead?
  def perform(dossier, siret)
    begin
      etablissement_attributes = APIEntrepriseService.get_etablissement_params_for_siret(siret, dossier.procedure.id)
    rescue
      return
    end

    if etablissement_attributes.present?
      if dossier.etablissement.present?
        dossier.etablissement.destroy
      end
      etablissement_attributes = ActionController::Parameters.new(etablissement_attributes).permit!
      etablissement = dossier.build_etablissement(etablissement_attributes)
      etablissement.save
    end
  end
end
