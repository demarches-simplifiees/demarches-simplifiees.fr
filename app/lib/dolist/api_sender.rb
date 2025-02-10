# frozen_string_literal: true

module Dolist
  class APISender
    def initialize(mail); end

    def deliver!(mail)
      if Dolist::API.rate_limited?
        Sentry.capture_message("Dolist: rate limit reached") if rand < 0.1
        raise Dolist::RateLimitError, "Rate limit reached" # ignored by sentry
      end

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
