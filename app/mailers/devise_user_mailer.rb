# Preview all emails at http://localhost:3000/rails/mailers/devise_user_mailer
class DeviseUserMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  helper MailerHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  include MailerDolistConcern
  include MailerMonitoringConcern
  layout 'mailers/layout'
  before_action :add_delivery_method, if: :forced_delivery?

  def template_paths
    ['devise_mailer']
  end

  def confirmation_instructions(record, token, opts = {})
    opts[:from] = NO_REPLY_EMAIL
    @procedure = opts[:procedure_after_confirmation] || nil
    @prefill_token = opts[:prefill_token]
    super
  end

  def add_delivery_method
    headers[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER] = SafeMailer.forced_delivery_method
  end

  def forced_delivery?
    SafeMailer.forced_delivery_method.present?
  end
end
