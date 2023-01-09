class EmailDeliveryObserver
  def self.delivered_email(message)
    return if message.to.nil?

    EmailEvent.create_from_message!(message, status: "dispatched")
  end
end
