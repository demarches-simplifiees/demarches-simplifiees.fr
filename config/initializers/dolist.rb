ActiveSupport.on_load(:action_mailer) do
  module Dolist
    class SMTP < ::Mail::SMTP
      def deliver!(mail)
        mail.from(CONTACT_EMAIL)
        mail.sender(CONTACT_EMAIL)
        mail['X-ACCOUNT-ID'] = Rails.application.secrets.dolist[:account_id]

        mail['X-Dolist-Sending-Type'] = 'TransactionalService' # send even if the target is not active

        super(mail)
      end
    end
  end

  ActionMailer::Base.add_delivery_method :dolist, Dolist::SMTP

  ActionMailer::Base.dolist_settings = {
    user_name: Rails.application.secrets.dolist[:username],
    password: Rails.application.secrets.dolist[:password],
    address: 'smtp.dolist.net',
    port: 587,
    authentication: 'plain',
    enable_starttls_auto: true
  }
end
