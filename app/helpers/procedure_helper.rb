module ProcedureHelper
  def procedure_lien(procedure)
    if procedure.brouillon?
      commencer_test_url(path: procedure.path)
    else
      commencer_url(path: procedure.path)
    end
  end

  def procedure_libelle(procedure)
    parts = procedure.brouillon? ? [tag.span('démarche en test', class: 'badge')] : []
    parts << procedure.libelle
    safe_join(parts, ' ')
  end

  def procedure_publish_text(procedure, key)
    # i18n-tasks-use t('modal.publish.body.publish')
    # i18n-tasks-use t('modal.publish.body.reopen')
    # i18n-tasks-use t('modal.publish.submit.publish')
    # i18n-tasks-use t('modal.publish.submit.reopen')
    # i18n-tasks-use t('modal.publish.title.publish')
    # i18n-tasks-use t('modal.publish.title.reopen')
    action = procedure.close? ? :reopen : :publish
    t(action, scope: [:modal, :publish, key])
  end

  def types_de_champ_data(procedure)
    {
      isAnnotation: false,
      typeDeChampsTypes: TypeDeChamp.type_de_champ_types_for(procedure, current_user),
      typeDeChamps: (procedure.draft_revision ? procedure.draft_revision : procedure).types_de_champ.as_json_for_editor,
      baseUrl: admin_procedure_types_de_champ_path(procedure),
      directUploadUrl: rails_direct_uploads_url
    }
  end

  def types_de_champ_private_data(procedure)
    {
      isAnnotation: true,
      typeDeChampsTypes: TypeDeChamp.type_de_champ_types_for(procedure, current_user),
      typeDeChamps: (procedure.draft_revision ? procedure.draft_revision : procedure).types_de_champ_private.as_json_for_editor,
      baseUrl: admin_procedure_types_de_champ_path(procedure),
      directUploadUrl: rails_direct_uploads_url
    }
  end

  def procedure_auto_archive_date(procedure)
    I18n.l(procedure.auto_archive_on - 1.day, format: '%-d %B %Y')
  end

  def procedure_auto_archive_time(procedure)
    "à 23 h 59 (heure de " + Rails.application.config.time_zone.gsub(/^.*\//, "") + ")"
  end

  def procedure_auto_archive_datetime(procedure)
    procedure_auto_archive_date(procedure) + ' ' + procedure_auto_archive_time(procedure)
  end
end
