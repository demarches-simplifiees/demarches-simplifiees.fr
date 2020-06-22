module ProcedureHelper
  def procedure_lien(procedure)
    if procedure.brouillon?
      commencer_test_url(path: procedure.path)
    else
      commencer_url(path: procedure.path)
    end
  end

  def procedure_libelle(procedure)
    parts = procedure.brouillon? ? [content_tag(:span, 'démarche en test', class: 'badge')] : []
    parts << procedure.libelle
    safe_join(parts, ' ')
  end

  def procedure_modal_text(procedure, key)
    action = procedure.close? ? :reopen : :publish
    t(action, scope: [:modal, :publish, key])
  end

  def types_de_champ_data(procedure)
    {
      isAnnotation: false,
      typeDeChampsTypes: TypeDeChamp.type_de_champ_types_for(procedure, current_user),
      typeDeChamps: procedure.types_de_champ.as_json_for_editor,
      baseUrl: procedure_types_de_champ_path(procedure),
      directUploadUrl: rails_direct_uploads_url
    }
  end

  def types_de_champ_private_data(procedure)
    {
      isAnnotation: true,
      typeDeChampsTypes: TypeDeChamp.type_de_champ_types_for(procedure, current_user),
      typeDeChamps: procedure.types_de_champ_private.as_json_for_editor,
      baseUrl: procedure_types_de_champ_path(procedure),
      directUploadUrl: rails_direct_uploads_url
    }
  end

  def procedure_auto_archive_date(procedure)
    I18n.l(procedure.auto_archive_on - 1.day, format: '%-d %B %Y')
  end

  def procedure_auto_archive_time(procedure)
    "à 23 h 59 (heure de " + Rails.application.config.time_zone + ")"
  end

  def procedure_auto_archive_datetime(procedure)
    procedure_auto_archive_date(procedure) + ' ' + procedure_auto_archive_time(procedure)
  end
end
