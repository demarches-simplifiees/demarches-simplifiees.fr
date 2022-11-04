module ProcedureHelper
  def procedure_lien(procedure)
    if procedure.brouillon?
      commencer_test_url(path: procedure.path)
    else
      commencer_url(path: procedure.path)
    end
  end

  def procedure_libelle(procedure)
    parts = procedure.brouillon? ? [procedure_badge(procedure)] : []
    parts << procedure.libelle
    safe_join(parts, ' ')
  end

  def procedure_badge(procedure)
    return nil unless procedure.brouillon?

    tag.span(t('helpers.procedure.testing_procedure'), class: 'fr-badge')
  end

  def procedure_publish_label(procedure, key)
    # i18n-tasks-use t('modal.publish.body.publish')
    # i18n-tasks-use t('modal.publish.body.reopen')
    # i18n-tasks-use t('modal.publish.submit.publish')
    # i18n-tasks-use t('modal.publish.submit.reopen')
    # i18n-tasks-use t('modal.publish.title.publish')
    # i18n-tasks-use t('modal.publish.title.reopen')
    action = procedure.close? ? :reopen : :publish
    t(action, scope: [:modal, :publish, key])
  end

  # Returns a hash of { attribute: full_message } errors.
  def procedure_publication_errors(procedure)
    procedure.validate(:publication)
    procedure.errors.to_hash(full_messages: true).except(:path)
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

  def can_manage_groupe_instructeurs?(procedure)
    procedure.routing_enabled? && current_administrateur&.owns?(procedure)
  end

  def can_send_groupe_message?(procedure)
    procedure.dossiers
      .state_brouillon
      .includes(:groupe_instructeur)
      .exists?(groupe_instructeur: current_instructeur.groupe_instructeurs)
  end

  def url_or_email_to_lien_dpo(procedure)
    URI::MailTo.build([procedure.lien_dpo, "subject="]).to_s
  rescue URI::InvalidComponentError
    uri = URI.parse(procedure.lien_dpo)
    return "//#{uri}" if uri.scheme.nil?
    uri.to_s
  end

  def estimated_fill_duration_minutes(procedure)
    seconds = procedure.active_revision.estimated_fill_duration
    minutes = (seconds / 60.0).round
    [1, minutes].max
  end
end
