# frozen_string_literal: true

module Dolist
  class APISender
    def initialize(mail); end

    def deliver!(mail)
      handle_rate_limit!(mail)

      client = API.new
      response = client.send_email(mail)
      case response.with_indifferent_access
      in { Result: String } => response
        mail.message_id = response.dig(:Result)
      in { ResponseStatus: { ErrorCode: "439", Message: "The contact is read only." } }
        fail ContactReadOnlyError, "The contact is read only."
      in { ResponseStatus: { ErrorCode: ignorable_code } } if ignorable_code.in?(Dolist::API::IGNORABLE_API_ERROR_CODE)
        invalid_contact_status = client.fetch_contact_status(mail.to.first)

        if invalid_contact_status
          fail IgnorableError, "DoList delivery error. contact unreachable: #{invalid_contact_status}"
        else
          fail "DoList delivery error. Body: #{response}"
        end
      else
        fail "DoList delivery error. Body: #{response}"
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
