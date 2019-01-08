module DossierLinkHelper
  def dossier_linked_path(user, dossier)
    if user.is_a?(Gestionnaire)
      if dossier.procedure.gestionnaires.include?(user)
        gestionnaire_dossier_path(dossier.procedure, dossier)
      else
        avis = dossier.avis.find_by(gestionnaire: user)
        if avis.present?
          gestionnaire_avis_path(avis)
        end
      end
    elsif user.owns_or_invite?(dossier)
      dossier_path(dossier)
    end
  end
end
