# The certificate and secret key are not fetched from secrets.yml because there is a problem to set a secret key from a multiline env var"
# So we fetch env var directly here

if Rails.env.production?
  SamlIdp.config.x509_certificate = ENV.fetch("SAML_IDP_CERTIFICATE")
  SamlIdp.config.secret_key = ENV.fetch("SAML_IDP_SECRET_KEY")
end
