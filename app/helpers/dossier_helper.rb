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

  def dossier_submission_is_closed?(dossier)
    dossier.brouillon? && dossier.procedure.archivee?
  end
end
