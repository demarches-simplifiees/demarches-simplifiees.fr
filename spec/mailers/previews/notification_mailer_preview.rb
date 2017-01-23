class NotificationMailerPreview < ActionMailer::Preview

  def dossier_received
    NotificationMailer.dossier_received(Dossier.last)
  end

  def dossier_validated
    NotificationMailer.dossier_validated(Dossier.last)
  end

end
