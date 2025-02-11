# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/devise_user_mailer
class DeviseUserMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  helper MailerHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  include MailerDefaultsConfigurableConcern
  include MailerDolistConcern
  include MailerMonitoringConcern
  include PriorityDeliveryConcern

  layout 'mailers/layout'
  default from: "#{APPLICATION_NAME} <#{CONTACT_EMAIL}>"

  def template_paths
    ['devise_mailer']
  end

  # Note: this devise hook (like any callback) is called *after* the action,
  # because we use mailers with Mailer.action_name() syntax
  # instead of parameterized Mailer.with().action_name.
  # So any action using Current must manually call `configure_defaults_for_user`
  def initialize_from_record(record)
    configure_defaults_for_user(record)

    super
  end

  def confirmation_instructions(record, token, opts = {})
    configure_defaults_for_user(record)

    opts[:from] = Current.no_reply_email
    opts[:reply_to] = Current.no_reply_email
    @procedure = opts[:procedure_after_confirmation] || nil
    @prefill_token = opts[:prefill_token]

    bypass_unverified_mail_protection!

    I18n.with_locale(record.locale) do
      super
    end
  end

  def reset_password_instructions(record, token, opts = {})
    bypass_unverified_mail_protection!

    super
  end

  def self.critical_email?(action_name)
    true
  end
end
