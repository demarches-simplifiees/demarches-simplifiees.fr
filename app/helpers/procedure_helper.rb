module ProcedureHelper
  def procedure_lien(procedure)
    if procedure.procedure_path.present?
      if procedure.brouillon_avec_lien?
        commencer_test_url(procedure_path: procedure.path)
      else
        commencer_url(procedure_path: procedure.path)
      end
    end
  end

  def procedure_libelle(procedure)
    parts = [procedure.libelle]
    if procedure.brouillon?
      parts << '(brouillon)'
    end
    parts.join(' ')
  end

  def procedure_modal_text(procedure, key)
    action = procedure.archivee? ? :reopen : :publish
    t(action, scope: [:modal, :publish, key])
  end
end
