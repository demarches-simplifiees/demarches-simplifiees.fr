class NotificationMailerPreview < ActionMailer::Preview
  def send_dossier_received
    NotificationMailer.send_dossier_received(Dossier.last)
  end

  def send_initiated_notification
    p = Procedure.where(id: Mails::InitiatedMail.where("body like ?", "%<img%").pluck(:procedure_id).uniq).order("RANDOM()").first
    NotificationMailer.send_initiated_notification(p.dossiers.last)
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
