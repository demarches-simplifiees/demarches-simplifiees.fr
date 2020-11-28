# OmniAuth GET requests may be vulnerable to CSRF.
# Ensure that OmniAuth only uses POST requests.
# See https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
OmniAuth.config.allowed_request_methods = [:post]
# puts "configuration facebook"
# Rails.application.config.middleware.use OmniAuth::Builder do
#  provider :facebook, Rails.application.secrets.facebook[:client_id], Rails.application.secrets.facebook[:client_secret], scope: 'email'
#  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"],ENV["GOOGLE_CLIENT_SECRET"], skip_jwt: true
#  on_failure { |env| OmniauthController.action(:failure).call(env) }
# end
