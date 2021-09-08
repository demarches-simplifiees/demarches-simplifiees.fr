# We want to register an interceptor, but we can't make the action idempotent
# (because there's no way to peek at the currently registered interceptors).
#
# To make zeitwerk happy, instead signal that we don't want the
# DynamicSmtpSettingsInterceptor constant to be auto-loaded, by:
# - adding it to a non-autoloaded-path (/lib),
# - requiring it explicitely.
#
# See https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoloading-when-the-application-boots
require 'action_mailer/dynamic_smtp_settings_interceptor'

ActiveSupport.on_load(:action_mailer) do
  ActionMailer::Base.register_interceptor DynamicSmtpSettingsInterceptor
end
