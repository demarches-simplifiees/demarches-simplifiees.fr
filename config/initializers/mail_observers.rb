# frozen_string_literal: true

# Must be registered *before* loading custom delivery methods
# otherwise the observer won't be invoked.
#
require_relative "../../app/services/email_delivery_observer"
require_relative "../../app/services/email_delivering_interceptor"

ActiveSupport.on_load(:action_mailer) do |mailer|
  mailer.register_interceptor EmailDeliveringInterceptor
  mailer.register_observer EmailDeliveryObserver
end
