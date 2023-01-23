# Preview all emails at http://localhost:3000/rails/mailers/devise_user_mailer
class DeviseUserMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  helper MailerHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  include MailerDolistConcern
  include MailerMonitoringConcern
  include BalancedDeliveryConcern
  layout 'mailers/layout'

  def template_paths
    ['devise_mailer']
  end

  def confirmation_instructions(record, token, opts = {})
    opts[:from] = NO_REPLY_EMAIL
    @procedure = opts[:procedure_after_confirmation] || nil
    @prefill_token = opts[:prefill_token]
    super
  end

  def forced_delivery_for_action?
    true
  end
end
