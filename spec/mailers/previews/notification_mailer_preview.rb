class NotificationMailerPreview < ActionMailer::Preview
  def send_notification
    NotificationMailer.send_initiated_notification(Dossier.last)
  end

  def send_draft_notification
    NotificationMailer.send_draft_notification(Dossier.last)
  end
end
