module MailRateLimitable
  extend ActiveSupport::Concern

  included do
    def initialize(rate_limiter: MailRateLimiter.new(limit: 200, window: 10.minutes))
      @rate_limiter = rate_limiter
    end

    def safe_send_email(mail)
      @rate_limiter.send_with_delay(mail)
    end
  end
end
