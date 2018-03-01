class ApplicationMailer < ActionMailer::Base
  default from: "'demarches-simplifiees.fr' <#{I18n.t('dynamics.contact_email')}>"
  layout 'mailer'
end
