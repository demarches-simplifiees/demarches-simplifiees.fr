class ApplicationMailer < ActionMailer::Base
  default from: "'Téléprocédures Simplifiées' <#{I18n.t('dynamics.contact_email')}>"
  layout 'mailer'
end
