class ApplicationMailer < ActionMailer::Base
  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "#{SITE_NAME} <#{CONTACT_EMAIL}>"
  layout 'mailer'
end
