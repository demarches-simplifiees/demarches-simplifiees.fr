ActiveSupport.on_load(:action_mailer) do
  module Dolist
    class IgnorableError < StandardError
    end

    class SMTP < ::Mail::SMTP
      def deliver!(mail)
        mail.from(ENV['DOLIST_NO_REPLY_EMAIL'])
        mail.sender(ENV['DOLIST_NO_REPLY_EMAIL'])
        mail['X-ACCOUNT-ID'] = Rails.application.secrets.dolist[:account_id]
        mail['X-Dolist-Sending-Type'] = 'TransactionalService' # send even if the target is not active

        super(mail)
      end
    end

    class ApiSender
      def initialize(mail); end

      def deliver!(mail)
        client = Dolist::API.new
        response = client.send_email(mail)
        if response&.dig("Result")
          mail.message_id = response.dig("Result")
        else
          _, invalid_contact_status = client.ignorable_error?(response, mail)

          if invalid_contact_status
            raise Dolist::IgnorableError.new("DoList delivery error. contact unreachable: #{invalid_contact_status}")
          else
            fail "DoList delivery error. Body: #{response}"
          end
        end
      end
    end
  end

  ActionMailer::Base.add_delivery_method :dolist_smtp, Dolist::SMTP
  ActionMailer::Base.dolist_smtp_settings = {
    user_name: Rails.application.secrets.dolist[:username],
    password: Rails.application.secrets.dolist[:password],
    address: 'smtp.dolist.net',
    port: 587,
    authentication: 'plain',
    enable_starttls_auto: true
  }

  ActionMailer::Base.add_delivery_method :dolist_api, Dolist::ApiSender
end
