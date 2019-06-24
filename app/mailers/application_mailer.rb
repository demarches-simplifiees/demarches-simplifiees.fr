class ApplicationMailer < ActionMailer::Base
  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "demarches-simplifiees.fr <#{CONTACT_EMAIL}>"
  layout 'mailer'
end
