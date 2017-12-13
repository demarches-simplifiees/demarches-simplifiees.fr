module DossierLinkHelper
  def dossier_linked_path(gestionnaire, dossier)
    if dossier.procedure.gestionnaires.include?(gestionnaire)
      dossier_path(dossier.procedure, dossier)
    else
      avis = dossier.avis.find_by(gestionnaire: gestionnaire)
      if avis.present?
        avis_path(avis)
      end
    end
  end
end
