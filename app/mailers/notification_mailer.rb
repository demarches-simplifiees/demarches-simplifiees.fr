class NotificationMailer < ApplicationMailer
  default to: Proc.new { @dossier.user.email }

  def send_dossier_received(dossier_id)
    dossier = Dossier.find(dossier_id)
    send_notification(dossier, dossier.procedure.received_mail_template)
  end

  def send_notification(dossier, mail_template, attestation = nil)
    @dossier = dossier

    subject = mail_template.subject_for_dossier dossier
    body = mail_template.body_for_dossier dossier

    if attestation.present?
      attachments['attestation.pdf'] = attestation
    end

    create_commentaire_for_notification(dossier, subject, body)

    mail(subject: subject) { |format| format.html { body } }
  end

  def send_draft_notification(dossier)
    @dossier = dossier

    mail(subject: "Retrouvez votre brouillon pour la démarche : #{dossier.procedure.libelle}")
  end

  def new_answer(dossier)
    @dossier = dossier

    mail(subject: "Nouveau message pour votre dossier TPS nº #{dossier.id}")
  end

  private

  def create_commentaire_for_notification(dossier, subject, body)
    Commentaire.create(
      dossier: dossier,
      email: I18n.t("dynamics.contact_email"),
      body: ["[#{subject}]", body].join("<br><br>")
    )
  end
end
