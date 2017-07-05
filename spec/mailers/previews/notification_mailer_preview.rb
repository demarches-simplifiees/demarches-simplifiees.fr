class NotificationMailerPreview < ActionMailer::Preview
  def send_notification
    NotificationMailer.send_notification(Dossier.last, Dossier.last.procedure.initiated_mail_template)
  end
end
