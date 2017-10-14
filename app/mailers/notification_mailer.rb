class NotificationMailer < ApplicationMailer
  default to: Proc.new { @user.email }

  after_action :create_commentaire_for_notification, only: [:send_notification, :send_dossier_received]

  def send_dossier_received(dossier_id)
    dossier = Dossier.find(dossier_id)
    send_notification(dossier, dossier.procedure.received_mail_template)
  end

  def send_notification(dossier, mail_template, attestation = nil)
    vars_mailer(dossier)

    @object = mail_template.object_for_dossier dossier
    @body = mail_template.body_for_dossier dossier

    if attestation.present?
      attachments['attestation.pdf'] = attestation
    end

    mail(subject: @object) { |format| format.html { @body } }
  end

  def new_answer(dossier)
    send_mail dossier, "Nouveau message pour votre dossier TPS nº #{dossier.id}"
  end

  private

  def create_commentaire_for_notification
    Commentaire.create(
      dossier: @dossier,
      email: I18n.t("dynamics.contact_email"),
      body: ["[#{@object}]", @body].join("<br><br>")
    )
  end

  def vars_mailer(dossier)
    @dossier = dossier
    @user = dossier.user
  end

  def send_mail(dossier, subject)
    vars_mailer dossier

    mail(subject: subject)
  end
end
