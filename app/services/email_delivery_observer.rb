# frozen_string_literal: true

class EmailDeliveryObserver
  def self.delivered_email(message)
    EmailEvent.create_from_message!(message, status: "dispatched")
  end
end
