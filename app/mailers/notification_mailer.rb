# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer

# A Notification is attached as a Comment to the relevant discussion,
# then sent by email to the user.
#
# The subject and body of a Notification can be customized by each demarche.
#
class NotificationMailer < ApplicationMailer
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

  def send_notification(dossier, mail_template)
    @dossier = dossier

    email = dossier.user.email

    subject = mail_template.subject_for_dossier(dossier)
    body = mail_template.body_for_dossier(dossier)

    create_commentaire_for_notification(dossier, subject, body)

    mail_with_reply_hook(dossier, subject: subject, to: email) do |format|
      # rubocop:disable Rails/OutputSafety
      format.html { render(html: body.html_safe, layout: 'mailers/notification') }
      # rubocop:enable Rails/OutputSafety
    end
  end

  def create_commentaire_for_notification(dossier, subject, body)
    Commentaire.create(
      dossier: dossier,
      email: CONTACT_EMAIL,
      body: ["[#{subject}]", body].join("<br><br>")
    )
  end
end
