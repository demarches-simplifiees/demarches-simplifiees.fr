# frozen_string_literal: true

# The certificate and secret key are not fetched from secrets.yml because there is a problem to set a secret key from a multiline env var"
# So we fetch env var directly here

if ENV['SAML_IDP_ENABLED'] == 'enabled'
  SamlIdp.configure do |config|
    config.base_saml_location = "https://#{ENV['APP_HOST']}/saml/metadata"
    config.x509_certificate = ENV.fetch("SAML_IDP_CERTIFICATE")
    config.secret_key = ENV.fetch("SAML_IDP_SECRET_KEY")
    config.single_service_post_location = "https://#{ENV['APP_HOST']}/saml/auth"
    config.single_service_redirect_location = "https://#{ENV['APP_HOST']}/saml/auth"

    config.name_id.formats = {
      "1.1" => {
        email_address: -> (principal) { principal.email }
      },
      "2.0" => {
        transient: -> (principal) { principal.email },
        persistent: -> (p) { p.id }
      }
    }

    service_providers = {}
    if ENV['SAML_DOLIST_HOST'].present?
      service_providers["https://#{ENV.fetch('SAML_DOLIST_HOST')}"] =
        {
          response_hosts: [ENV.fetch('SAML_DOLIST_HOST')],
          cert: ENV.fetch("SAML_DOLIST_CERTIFICATE")
        }
    end

    config.service_provider.finder = -> (entity_id) do
      service_providers[entity_id]
    end
  end
end
