Mailjet.configure do |config|
  config.api_key = Rails.application.secrets.mailjet[:api_key]
  config.secret_key = Rails.application.secrets.mailjet[:secret_key]
  config.default_from = CONTACT_EMAIL

  # puts "Mail configuration: default_from=#{config.default_from}, api_key=#{config.api_key[0..8]}... secret_key=#{config.secret_key[0..8]}..."
end
