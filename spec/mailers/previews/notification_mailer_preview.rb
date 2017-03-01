class NotificationMailerPreview < ActionMailer::Preview

  def dossier_received
    NotificationMailer.dossier_received(Dossier.last)
  end

end
