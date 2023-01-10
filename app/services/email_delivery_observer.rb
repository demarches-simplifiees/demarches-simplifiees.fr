class EmailDeliveryObserver
  def self.delivered_email(message)
    EmailEvent.create_from_message!(message, status: "dispatched")
  end
end
