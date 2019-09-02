module DossierLinkHelper
  def dossier_linked_path(user, dossier)
    if user.is_a?(Instructeur)
      if dossier.procedure.defaut_groupe_instructeur.instructeurs.include?(user)
        instructeur_dossier_path(dossier.procedure, dossier)
      else
        avis = dossier.avis.find_by(instructeur: user)
        if avis.present?
          instructeur_avis_path(avis)
        end
      end
    elsif user.owns_or_invite?(dossier)
      dossier_path(dossier)
    end
  end
end
