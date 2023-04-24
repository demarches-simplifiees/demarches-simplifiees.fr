module Dolist
  class SMTP < ::Mail::SMTP
    def deliver!(mail)
      mail.from(ENV['DOLIST_NO_REPLY_EMAIL'])
      mail.sender(ENV['DOLIST_NO_REPLY_EMAIL'])
      mail['X-ACCOUNT-ID'] = Rails.application.secrets.dolist[:account_id]
      mail['X-Dolist-Sending-Type'] = 'TransactionalService' # send even if the target is not active

      super(mail)
    end
  end
end
