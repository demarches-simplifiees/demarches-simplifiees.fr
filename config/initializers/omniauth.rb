# OmniAuth GET requests may be vulnerable to CSRF.
# Ensure that OmniAuth only uses POST requests.
# See https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
OmniAuth.config.allowed_request_methods = [:post]
