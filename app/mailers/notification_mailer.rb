class NotificationMailer < ApplicationMailer
  default to: Proc.new { @user.email }

  after_action :create_commentaire_for_notification, only: :send_notification

  def send_notification dossier, mail_template
    vars_mailer(dossier)

    @obj  = mail_template.object_for_dossier dossier
    @body = mail_template.body_for_dossier dossier

    mail(subject: @obj) { |format| format.html { @body } }
  end

  def new_answer dossier
    send_mail dossier, "Nouveau message pour votre dossier TPS nº #{dossier.id}"
  end

  private

  def create_commentaire_for_notification
    Commentaire.create(
      dossier: @dossier,
      email: "contact@tps.apientreprise.fr",
      body: ["[#{@obj}]", @body].join("<br><br>")
    )
  end

  def vars_mailer dossier
    @dossier = dossier
    @user = dossier.user
  end

  def send_mail dossier, subject
    vars_mailer dossier

    mail(subject: subject)
  end
end
