class EtablissementUpdateJob < ApplicationJob
  queue_as :default

  def perform(dossier, siret)
    etablissement_attributes = ApiEntrepriseService.get_etablissement_params_for_siret(siret, dossier.procedure_id)

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
