# A Mail delivery method that randomly balances the actual delivery between different
# methods.
#
# Usage:
#
# ```ruby
#   ActionMailer::Base.add_delivery_method :balancer, BalancerDeliveryMethod
#   config.action_mailer.balancer_settings = {
#     smtp: 25,
#     sendmail: 75
#   }
#   config.action_mailer.delivery_method = :balancer
# ```
#
# Be sure to restart your server when you modify this file.
class BalancerDeliveryMethod
  # Allows configuring the random number generator used for selecting a delivery method,
  # mostly for testing purposes.
  mattr_accessor :random, default: Random.new

  def initialize(settings)
    @delivery_methods = settings
  end

  def deliver!(mail)
    balanced_delivery_method = delivery_method(mail)
    ApplicationMailer.wrap_delivery_behavior(mail, balanced_delivery_method)
    mail.deliver
  end

  private

  def delivery_method(mail)
    @delivery_methods
      .flat_map { |delivery_method, weight| [delivery_method] * weight }
      .sample(random: self.class.random)
  end
end
