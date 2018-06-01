class ApplicationMailer < ActionMailer::Base
  default from: "demarches-simplifiees.fr <#{CONTACT_EMAIL}>"
  layout 'mailer'
end
