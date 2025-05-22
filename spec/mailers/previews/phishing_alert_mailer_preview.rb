class PhishingAlertMailerPreview < ActionMailer::Preview
  def notify
    PhishingAlertMailer.notify(User.first)
  end
end
