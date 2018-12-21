class ApplicationMailer < ActionMailer::Base
  default from: "#{SITE_NAME} <#{CONTACT_EMAIL}>"
  layout 'mailer'
end
