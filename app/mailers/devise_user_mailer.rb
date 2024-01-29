# Preview all emails at http://localhost:3000/rails/mailers/devise_user_mailer
class DeviseUserMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  helper MailerHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  include MailerDolistConcern
  include MailerMonitoringConcern
  include BalancedDeliveryConcern
  include PriorityDeliveryConcern

  layout 'mailers/layout'

  def template_paths
    ['devise_mailer']
  end

  def confirmation_instructions(record, token, opts = {})
    opts[:from] = NO_REPLY_EMAIL
    @procedure = opts[:procedure_after_confirmation] || nil
    @prefill_token = opts[:prefill_token]
    I18n.with_locale(record&.locale || I18n.default_locale) { super }
  end

  def reset_password_instructions(record, token, opts = {})
    I18n.with_locale(record&.locale || I18n.default_locale) { super }
  end

  def unlock_instructions(record, token, opts = {})
    I18n.with_locale(record&.locale || I18n.default_locale) { super }
  end

  def email_changed(record, opts = {})
    I18n.with_locale(record&.locale || I18n.default_locale) { super }
  end

  def password_change(record, opts = {})
    I18n.with_locale(record&.locale || I18n.default_locale) { super }
  end

  def self.critical_email?(action_name)
    true
  end
end
