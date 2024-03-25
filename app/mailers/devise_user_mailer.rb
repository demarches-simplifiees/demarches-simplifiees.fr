# Preview all emails at http://localhost:3000/rails/mailers/devise_user_mailer
class DeviseUserMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  helper MailerHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  include MailerDolistConcern
  include MailerMonitoringConcern
  include MailerHeadersConfigurableConcern
  include BalancedDeliveryConcern
  include PriorityDeliveryConcern

  layout 'mailers/layout'

  def template_paths
    ['devise_mailer']
  end

  def confirmation_instructions(record, token, opts = {})
    configure_defaults_for_user(record)

    opts[:from] = Current.no_reply_email
    opts[:reply_to] = Current.no_reply_email
    @procedure = opts[:procedure_after_confirmation] || nil
    @prefill_token = opts[:prefill_token]
    super
  end

  def self.critical_email?(action_name)
    true
  end
end
