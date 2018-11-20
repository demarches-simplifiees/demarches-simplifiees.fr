class NotificationMailerPreview < ActionMailer::Preview
  def send_dossier_received
    NotificationMailer.send_dossier_received(Dossier.last)
  end

  def send_initiated_notification
    NotificationMailer.send_initiated_notification(Dossier.last)
  end

  def send_closed_notification
    NotificationMailer.send_closed_notification(Dossier.last)
  end

  def send_refused_notification
    NotificationMailer.send_refused_notification(Dossier.last)
  end

  def send_without_continuation_notification
    NotificationMailer.send_without_continuation_notification(Dossier.last)
  end
end
