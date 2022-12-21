# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer

# A Notification is attached as a Comment to the relevant discussion,
# then sent by email to the user.
#
# The subject and body of a Notification can be customized by each demarche.
#
class NotificationMailer < ApplicationMailer
  include ActionView::Helpers::SanitizeHelper

  before_action :set_dossier
  after_action :create_commentaire_for_notification

  helper ServiceHelper
  helper MailerHelper

  layout 'mailers/notifications_layout'
  default from: NO_REPLY_EMAIL

  def send_notification
    @service = @dossier.procedure.service
    @logo_url = attach_logo(@dossier.procedure)
    @rendered_template = sanitize(@body)
    attachments[@attachment[:filename]] = @attachment[:content] if @attachment.present?

    I18n.with_locale(@dossier.user_locale) do
      mail(subject: @subject, to: @email, template_name: 'send_notification')
    end
  end

  def self.send_en_construction_notification(dossier)
    with(dossier: dossier, state: Dossier.states.fetch(:en_construction)).send_notification
  end

  def self.send_en_instruction_notification(dossier)
    with(dossier: dossier, state: Dossier.states.fetch(:en_instruction)).send_notification
  end

  def self.send_accepte_notification(dossier)
    with(dossier: dossier, state: Dossier.states.fetch(:accepte)).send_notification
  end

  def self.send_refuse_notification(dossier)
    with(dossier: dossier, state: Dossier.states.fetch(:refuse)).send_notification
  end

  def self.send_sans_suite_notification(dossier)
    with(dossier: dossier, state: Dossier.states.fetch(:sans_suite)).send_notification
  end

  private

  def set_dossier
    @dossier = params[:dossier]

    if @dossier.skip_user_notification_email?
      mail.perform_deliveries = false
    else
      I18n.with_locale(@dossier.user_locale) do
        mail_template = @dossier.procedure.mail_template_for(params[:state])

        @email = @dossier.user_email_for(:notification)
        @subject = mail_template.subject_for_dossier(@dossier)
        @body = mail_template.body_for_dossier(@dossier)
        @actions = mail_template.actions_for_dossier(@dossier)
        @attachment = mail_template.attachment_for_dossier(@dossier)
      end
    end
  end

  def create_commentaire_for_notification
    body = ["[#{@subject}]", @body].join("<br><br>")
    CommentaireService.create!(CONTACT_EMAIL, @dossier, body: body)
  end
end
