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
    "à 23 h 59 (heure de " + Rails.application.config.time_zone + ")"
  end

  def procedure_auto_archive_datetime(procedure)
    procedure_auto_archive_date(procedure) + ' ' + procedure_auto_archive_time(procedure)
  end

  def api_particulier_sources_checkboxes(procedure_mask, parent, child)
    return unless procedure_mask.fetch(parent, {}).key?(child)

    mask = procedure_mask.dig(parent, child)
    form_prefix = "procedure[#{parent}]"
    i18n_scope = "api_particulier.entities.#{parent}"

    capture do
      if mask.is_a?(Hash)
        api_particulier_sources_ul(mask, form_prefix: "#{form_prefix}[#{child}]", i18n_scope: "#{i18n_scope}.#{child}")
      else
        api_particulier_sources_checkbox(form_prefix, child, mask, i18n_scope: i18n_scope)
      end
    end
  end

  private

  def api_particulier_sources_checkbox(key, value, checked, label: nil, i18n_scope: nil)
    concat(tag.label do
      concat(check_box key, value, checked: ActiveModel::Type::Boolean.new.cast(checked))
      concat(label || t(value, scope: i18n_scope))
    end)
  end

  def api_particulier_sources_ul(mask, form_prefix: nil, i18n_scope: nil)
    concat(tag.strong(t(:libelle, scope: i18n_scope).capitalize))
    concat(tag.ul(class: "procedure-admin-api-particulier-sources") do
      mask.each do |k, v|
        if v.is_a?(Hash)
          concat(tag.li { api_particulier_sources_ul(v, form_prefix: "#{form_prefix}[#{k}]", i18n_scope: "#{i18n_scope}.#{k}") })
        else
          concat(tag.li { api_particulier_sources_checkbox(form_prefix, k, v, i18n_scope: i18n_scope) })
        end
      end
    end)
  end
end
