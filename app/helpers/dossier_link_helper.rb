# frozen_string_literal: true

module DossierLinkHelper
  def dossier_linked_path(user, dossier)
    if user.is_a?(Instructeur)
      if user.groupe_instructeurs.include?(dossier.groupe_instructeur)
        instructeur_dossier_path(dossier.procedure, dossier)
      end
    elsif user.owns_or_invite?(dossier)
      dossier_path(dossier)
    end
  end
end
