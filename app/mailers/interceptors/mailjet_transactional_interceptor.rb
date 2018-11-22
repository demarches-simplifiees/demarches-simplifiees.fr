# Configure some emails using `:mailjet` delivery method to be sent through the transactional Mailjet account.
#
# N.B.: this interceptor is a no-op when using `:mailjet_api` instead of `:mailjet`, or any other delivery method.
class MailjetTransactionalInterceptor
  class << self
    # ActionMailer hook
    def delivering_email(message)
      if use_transactional?(message)
        Rails.logger.info("Using Mailjet transactionnal account to send the email")
        # The delivery_method has already been instanciated with options, so
        # `delivery_method_options` is no longer available.
        # We have to re-configure the SMTP delivery method instance directly.
        message.delivery_method.settings[:user_name] = transactional_api_key
        message.delivery_method.settings[:password] = transactional_secret_key
      end
    end

    private

    def use_transactional?(message)
      if message.delivery_method.class.to_s != 'Mailjet::Mailer'
        Rails.logger.info('Skip Mailjet transactional account: mails are not sent using the `:mailjet` mailer.')
        return false
      end

      if transactional_api_key.blank? || transactional_secret_key.blank?
        Rails.logger.info('Skip Mailjet transactional account: transactional API keys are not defined')
        return false
      end

      if !recipients_allowed?(message)
        Rails.logger.info('Skip Mailjet transactional account: some email addresses are not allowed')
        return false
      end

      if rand > transactional_ratio
        Rails.logger.info('Skip Mailjet transactional account: random selection above the transactional ratio')
        return false
      end

      true
    end

    def transactional_api_key
      ENV['MAILJET_TRANSACTIONAL_API_KEY']
    end

    def transactional_secret_key
      ENV['MAILJET_TRANSACTIONAL_SECRET_KEY']
    end

    def transactional_ratio
      # Note: to_f converts non-numerical strings to 0.0
      ENV.fetch('MAILJET_TRANSACTIONAL_RATIO', '0.0').to_f
    end

    # Return true if all recipients are on the authorized domains list
    def recipients_allowed?(message)
      # TODO: when we'll be more confident in the transactional account,
      # switch to a block list (instead of a safe list)
      safe_domains = ['gmail', 'yahoo', 'orange', 'gouv.fr']
      message.to_addrs.all? do |recipient_address|
        safe_domains.any? { |domain| recipient_address.include?(domain) }
      end
    end
  end
end
