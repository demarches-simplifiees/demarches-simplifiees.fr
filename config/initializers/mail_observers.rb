# Must be registered *before* loading custom delivery methods
# otherwise the observer won't be invoked.
#
ActiveSupport.on_load(:action_mailer) do |mailer|
  mailer.register_observer EmailDeliveryObserver
end
