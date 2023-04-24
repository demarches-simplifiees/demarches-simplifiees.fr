ActiveSupport.on_load(:action_mailer) do
  require "dolist/smtp"

  ActionMailer::Base.add_delivery_method :dolist_smtp, Dolist::SMTP
  ActionMailer::Base.dolist_smtp_settings = {
    user_name: Rails.application.secrets.dolist[:username],
    password: Rails.application.secrets.dolist[:password],
    address: 'smtp.dolist.net',
    port: 587,
    authentication: 'plain',
    enable_starttls_auto: true
  }

  ActionMailer::Base.add_delivery_method :dolist_api, Dolist::APISender
end
