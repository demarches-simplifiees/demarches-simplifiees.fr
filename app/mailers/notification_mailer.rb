class NotificationMailer < ApplicationMailer
  def new_answer(dossier)
    subject = "Nouveau message pour votre dossier demarches-simplifiees.fr nº #{dossier.id}"

    send_mail(dossier, subject)
  end

  def send_draft_notification(dossier)
    subject = "Retrouvez votre brouillon pour la démarche : #{dossier.procedure.libelle}"

    send_mail(dossier, subject)
  end

  def send_dossier_received(dossier)
    send_notification(dossier, dossier.procedure.received_mail_template)
  end

  def send_initiated_notification(dossier)
    send_notification(dossier, dossier.procedure.initiated_mail_template)
  end

  def send_closed_notification(dossier)
    send_notification(dossier, dossier.procedure.closed_mail_template)
  end

  def send_refused_notification(dossier)
    send_notification(dossier, dossier.procedure.refused_mail_template)
  end

  def send_without_continuation_notification(dossier)
    send_notification(dossier, dossier.procedure.without_continuation_mail_template)
  end

  private

  def send_mail(dossier, subject)
    @dossier = dossier
    email = dossier.user.email

    mail(subject: subject, to: email)
  end

  def send_notification(dossier, mail_template)
    email = dossier.user.email

    subject = mail_template.subject_for_dossier(dossier)
    body = mail_template.body_for_dossier(dossier)

    create_commentaire_for_notification(dossier, subject, body)

    mail(subject: subject, to: email) { |format| format.html { body } }
  end

  def create_commentaire_for_notification(dossier, subject, body)
    Commentaire.create(
      dossier: dossier,
      email: I18n.t("dynamics.contact_email"),
      body: ["[#{subject}]", body].join("<br><br>")
    )
  end
end
