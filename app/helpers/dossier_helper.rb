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

  def text_summary(dossier)
    if dossier.brouillon?
      parts = [
        "Dossier en brouillon répondant à la procédure ",
        dossier.procedure.libelle,
        " gérée par l'organisme ",
        dossier.procedure.organisation
      ]
    else
      parts = [
        "Dossier déposé le ",
        dossier.en_construction_at.localtime.strftime("%d/%m/%Y"),
        " sur la procédure ",
        dossier.procedure.libelle,
        " gérée par l'organisme ",
        dossier.procedure.organisation
      ]
    end

    parts.join
  end
end
