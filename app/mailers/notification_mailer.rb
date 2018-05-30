class NotificationMailer < ApplicationMailer
  default to: Proc.new { @user.email }

  def send_dossier_received(dossier_id)
    dossier = Dossier.find(dossier_id)
    send_notification(dossier, dossier.procedure.received_mail_template)
  end

  def send_draft_notification(dossier)
    vars_mailer(dossier)

    @subject = "Retrouvez votre brouillon pour la démarche : #{dossier.procedure.libelle}"

    mail(subject: @subject)
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

  def new_answer(dossier)
    send_mail(dossier, "Nouveau message pour votre dossier demarches-simplifiees.fr nº #{dossier.id}")
  end

  private

  def send_notification(dossier, mail_template)
    vars_mailer(dossier)

    @subject = mail_template.subject_for_dossier(dossier)
    @body = mail_template.body_for_dossier(dossier)

    create_commentaire_for_notification

    mail(subject: @subject) { |format| format.html { @body } }
  end

  def create_commentaire_for_notification
    Commentaire.create(
      dossier: @dossier,
      email: I18n.t("dynamics.contact_email"),
      body: ["[#{@subject}]", @body].join("<br><br>")
    )
  end

  def vars_mailer(dossier)
    @dossier = dossier
    @user = dossier.user
  end

  def send_mail(dossier, subject)
    vars_mailer(dossier)

    mail(subject: subject)
  end
end
