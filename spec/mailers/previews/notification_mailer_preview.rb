class NotificationMailerPreview < ActionMailer::Preview
  def send_notification
    NotificationMailer.send_notification(Dossier.last, Dossier.last.procedure.initiated_mail_template)
  end

  def send_draft_notification
    NotificationMailer.send_draft_notification(Dossier.last)
  end
end
