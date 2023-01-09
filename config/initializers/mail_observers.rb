Rails.application.configure do
  config.action_mailer.observers = ['EmailDeliveryObserver']
end
