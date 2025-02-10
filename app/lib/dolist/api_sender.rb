# frozen_string_literal: true

module Dolist
  class APISender
    def initialize(mail); end

    def deliver!(mail)
      handle_rate_limit!(mail)

      client = API.new
      response = client.send_email(mail)
      if response&.dig("Result")
        mail.message_id = response.dig("Result")
      else
        _, invalid_contact_status = client.ignorable_error?(response, mail)

        if invalid_contact_status
          fail IgnorableError, "DoList delivery error. contact unreachable: #{invalid_contact_status}"
        else
          fail "DoList delivery error. Body: #{response}"
        end
      end
    end

    private

    def handle_rate_limit!(mail)
      if API.rate_limited?
        Sentry.capture_message("Dolist: rate limit reached") if rand < 0.1
        fail RateLimitError, "Rate limit reached" # ignored by sentry
      end

      if !critical?(mail) && API.near_rate_limit?
        # Requeue le mail pour plus tard via une exception
        fail RetryLaterError, "Near rate limit, postponing non-critical email"
      end
    end

    def critical?(mail)
      mail[PriorityDeliveryConcern::CRITICAL_HEADER]&.value == 'true'
    end
  end
end
