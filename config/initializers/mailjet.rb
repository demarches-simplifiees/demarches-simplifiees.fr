require Rails.root.join('app', 'mailers', 'interceptors', 'mailjet_transactional_interceptor')

Mailjet.configure do |config|
  # By default use the API key for the standard Mailjet account
  config.api_key = Rails.application.secrets.mailjet[:api_key]
  config.secret_key = Rails.application.secrets.mailjet[:secret_key]
  config.default_from = CONTACT_EMAIL
end

ActionMailer::Base.register_interceptor(MailjetTransactionalInterceptor)
