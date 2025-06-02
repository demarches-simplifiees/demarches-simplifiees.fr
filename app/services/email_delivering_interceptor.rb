# frozen_string_literal: true

class EmailDeliveringInterceptor
  def self.delivering_email(message)
    EmailEvent.create_from_message!(message, status: "pending")
  end
end
