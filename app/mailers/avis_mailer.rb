# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def avis_invitation(avis, targeted_user_link = nil) # ensure re-entrance if existing AvisMailer.avis_invitation in queue
    if avis.dossier.visible_by_administration?
      targeted_user_link = avis.targeted_user_links
        .find_or_create_by(target_context: 'avis',
                                                  target_model_type: Avis.name,
                                                  target_model_id: avis.id,
                                                  user: avis.expert.user)
      @avis = avis
      email = @avis.expert&.email
      @url = targeted_user_link_url(targeted_user_link)
      subject = "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})"

      configure_defaults_for_email(email)
      mail(to: email, subject: subject)
    end
  end

  def avis_invitation_and_confirm_email(user, token, avis, targeted_user_link = nil) # ensure re-entrance if existing AvisMailer.avis_invitation in queue
    if avis.dossier.visible_by_administration?
      targeted_user_link = avis.targeted_user_links
        .find_or_create_by(target_context: 'avis',
                                                  target_model_type: Avis.name,
                                                  target_model_id: avis.id,
                                                  user: avis.expert.user)
      email = user.email
      @token = token
      @avis = avis
      @url = targeted_user_link_url(targeted_user_link)
      subject = "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})"

      bypass_unverified_mail_protection!

      configure_defaults_for_user(user)
      mail(to: email, subject: subject)
    end
  end

  # i18n-tasks-use t("avis_mailer.#{action}.subject")
  def notify_new_commentaire_to_expert(dossier, avis, expert)
    I18n.with_locale(dossier.user_locale) do
      @dossier = dossier
      @avis = avis
      @subject = default_i18n_subject(dossier_id: dossier.id, libelle_demarche: dossier.procedure.libelle)

      configure_defaults_for_user(expert.user)
      mail(to: expert.email, subject: @subject)
    end
  end

  def self.critical_email?(action_name)
    false
  end
end
