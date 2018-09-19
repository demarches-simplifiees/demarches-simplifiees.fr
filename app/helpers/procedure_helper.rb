module ProcedureHelper
  def procedure_lien(procedure)
    if procedure.path.present?
      if procedure.brouillon_avec_lien?
        commencer_test_url(procedure_path: procedure.path)
      else
        commencer_url(procedure_path: procedure.path)
      end
    end
  end

  def procedure_libelle(procedure)
    parts = procedure.brouillon? ? [content_tag(:span, 'démarche non publiée', class: 'badge')] : []
    parts << procedure.libelle
    safe_join(parts, ' ')
  end

  def procedure_modal_text(procedure, key)
    action = procedure.archivee? ? :reopen : :publish
    t(action, scope: [:modal, :publish, key])
  end

  def dossiers_deletion_warning(procedure)
    dossiers_count = procedure.dossiers.state_not_brouillon.count
    brouillons_count = procedure.dossiers.state_brouillon.count
    formatted_dossiers_count = nil
    formatted_brouillons_count = nil

    if dossiers_count > 0
      formatted_dossiers_count = pluralize(dossiers_count, "dossier", "dossiers")
    end

    if brouillons_count > 0
      formatted_brouillons_count = pluralize(brouillons_count, "brouillon", "brouillons")
    end

    formatted_combination = [formatted_dossiers_count, formatted_brouillons_count]
      .compact
      .join(" et ")

    [
      formatted_combination,
      dossiers_count + brouillons_count == 1 ? "est rattaché" : "sont rattachés",
      "à cette démarche, la suppression de cette démarche entrainera également leur suppression."
    ].join(" ")
  end
end
