module DossierHelper
  def button_or_label_class(dossier)
    if dossier.accepte?
      'accepted'
    elsif dossier.sans_suite?
      'without-continuation'
    elsif dossier.refuse?
      'refuse'
    end
  end

  def highlight_if_unseen_class(seen_at, updated_at)
    if seen_at&.<(updated_at)
      "highlighted"
    end
  end

  def delete_dossier_confirm(dossier)
    message = "Vous vous apprêtez à supprimer votre dossier ainsi que les informations qu’il contient. "
    if dossier.en_construction_ou_instruction?
      message += "Nous vous rappelons que toute suppression entraine l’annulation de la démarche en cours. "
    end
    message += "Confirmer la suppression ?"
  end
end
