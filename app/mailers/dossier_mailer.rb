# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailer < ApplicationMailer
  helper ServiceHelper
  helper MailerHelper
  helper ProcedureHelper

  layout 'mailers/layout'
  default from: NO_REPLY_EMAIL

  def notify_new_draft(dossier)
    I18n.with_locale(dossier.user_locale) do
      @dossier = dossier
      @service = dossier.procedure.service
      @logo_url = attach_logo(dossier.procedure)
      @subject = default_i18n_subject(libelle_demarche: dossier.procedure.libelle)

      mail(to: dossier.user_email_for(:notification), subject: @subject) do |format|
        format.html { render layout: 'mailers/notifications_layout' }
      end
    end
  end

  def notify_new_answer(dossier, body = nil)
    I18n.with_locale(dossier.user_locale) do
      @dossier = dossier
      @service = dossier.procedure.service
      @logo_url = attach_logo(dossier.procedure)
      @body = body
      @subject = default_i18n_subject(dossier_id: dossier.id, libelle_demarche: dossier.procedure.libelle)

      mail(to: dossier.user_email_for(:notification), subject: @subject) do |format|
        format.html { render layout: 'mailers/notifications_layout' }
      end
    end
  end

  def notify_new_commentaire_to_instructeur(dossier, instructeur_email)
    I18n.with_locale(dossier.user_locale) do
      @dossier = dossier
      @subject = default_i18n_subject(dossier_id: dossier.id, libelle_demarche: dossier.procedure.libelle)

      mail(to: instructeur_email, subject: @subject)
    end
  end

  def notify_new_dossier_depose_to_instructeur(dossier, instructeur_email)
    I18n.with_locale(dossier.user_locale) do
      @dossier = dossier
      @subject = default_i18n_subject(dossier_id: dossier.id, libelle_demarche: dossier.procedure.libelle)

      mail(to: instructeur_email, subject: @subject)
    end
  end

  def notify_revert_to_instruction(dossier)
    I18n.with_locale(dossier.user_locale) do
      @dossier = dossier
      @service = dossier.procedure.service
      @logo_url = attach_logo(dossier.procedure)
      @subject = default_i18n_subject(dossier_id: dossier.id, libelle_demarche: dossier.procedure.libelle)

      mail(to: dossier.user_email_for(:notification), subject: @subject) do |format|
        format.html { render layout: 'mailers/notifications_layout' }
      end
    end
  end

  def notify_brouillon_near_deletion(dossiers, to_email)
    I18n.with_locale(dossiers.first.user_locale) do
      @subject = default_i18n_subject(count: dossiers.size)
      @dossiers = dossiers

      mail(to: to_email, subject: @subject)
    end
  end

  def notify_brouillon_deletion(dossier_hashes, to_email)
    @subject = default_i18n_subject(count: dossier_hashes.size)
    @dossier_hashes = dossier_hashes

    mail(to: to_email, subject: @subject)
  end

  def notify_deletion_to_user(deleted_dossier, to_email)
    I18n.with_locale(deleted_dossier.user_locale) do
      @subject = default_i18n_subject(dossier_id: deleted_dossier.dossier_id)
      @deleted_dossier = deleted_dossier

      mail(to: to_email, subject: @subject)
    end
  end

  def notify_instructeur_deletion_to_user(deleted_dossier, to_email)
    I18n.with_locale(deleted_dossier.user_locale) do
      @subject = default_i18n_subject(libelle_demarche: deleted_dossier.procedure.libelle)
      @deleted_dossier = deleted_dossier

      mail(to: to_email, subject: @subject)
    end
  end

  def notify_deletion_to_administration(deleted_dossier, to_email)
    @subject = default_i18n_subject(dossier_id: deleted_dossier.dossier_id)
    @deleted_dossier = deleted_dossier

    mail(to: to_email, subject: @subject)
  end

  def notify_automatic_deletion_to_user(deleted_dossiers, to_email)
    I18n.with_locale(deleted_dossiers.first.user_locale) do
      @state = deleted_dossiers.first.state
      @subject = default_i18n_subject(count: deleted_dossiers.size)
      @deleted_dossiers = deleted_dossiers

      mail(to: to_email, subject: @subject)
    end
  end

  def notify_automatic_deletion_to_administration(deleted_dossiers, to_email)
    @subject = default_i18n_subject(count: deleted_dossiers.size)
    @deleted_dossiers = deleted_dossiers

    mail(to: to_email, subject: @subject)
  end

  def notify_near_deletion_to_user(dossiers, to_email)
    I18n.with_locale(dossiers.first.user_locale) do
      @state = dossiers.first.state
      @subject = default_i18n_subject(count: dossiers.size, state: @state)
      @dossiers = dossiers

      mail(to: to_email, subject: @subject)
    end
  end

  def notify_near_deletion_to_administration(dossiers, to_email)
    @state = dossiers.first.state
    @subject = default_i18n_subject(count: dossiers.size, state: @state)
    @dossiers = dossiers

    mail(to: to_email, subject: @subject)
  end

  def notify_groupe_instructeur_changed(instructeur, dossier)
    @subject = default_i18n_subject(dossier_id: dossier.id)
    @dossier = dossier

    mail(to: instructeur.email, subject: @subject)
  end

  def notify_brouillon_not_submitted(dossier)
    I18n.with_locale(dossier.user_locale) do
      @subject = default_i18n_subject(dossier_id: dossier.id)
      @dossier = dossier

      mail(to: dossier.user_email_for(:notification), subject: @subject)
    end
  end

  def notify_transfer(transfer)
    I18n.with_locale(transfer.user_locale) do
      @subject = default_i18n_subject(count: transfer.dossiers.size)
      @transfer = transfer

      mail(to: transfer.email, subject: @subject)
    end
  end

  protected

  # This is an override of `default_i18n_subject` method
  # https://api.rubyonrails.org/v5.0.0/classes/ActionMailer/Base.html#method-i-default_i18n_subject
  #
  # i18n-tasks-use t("dossier_mailer.#{action}.subject")
  def default_i18n_subject(interpolations = {})
    if interpolations[:state]
      mailer_scope = self.class.mailer_name.tr('/', '.')
      state = interpolations[:state].in?(Dossier::TERMINE) ? 'termine' : interpolations[:state]
      I18n.t("subject_#{state}", **interpolations.merge(scope: [mailer_scope, action_name]))
    else
      super
    end
  end
end
