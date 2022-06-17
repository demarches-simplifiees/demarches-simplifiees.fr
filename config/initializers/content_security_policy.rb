# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  images_whitelist = ["*.openstreetmap.org", "*.cloud.ovh.net", "*"]
  images_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  images_whitelist << URI(MATOMO_IFRAME_URL).host if MATOMO_IFRAME_URL.present?
  policy.img_src(:self, :data, :blob, *images_whitelist)

  # Javascript: allow us, SendInBlue and Matomo.
  # We need unsafe_inline because miniprofiler and us have some inline buttons :(
  scripts_whitelist = ["*.crisp.chat", "crisp.chat", "cdn.jsdelivr.net", "maxcdn.bootstrapcdn.com", "code.jquery.com"]
  scripts_whitelist << URI(MATOMO_IFRAME_URL).host if MATOMO_IFRAME_URL.present?
  policy.script_src(:self, :unsafe_eval, :unsafe_inline, :blob, *scripts_whitelist)

  # CSS: We have a lot of inline style, and some <style> tags.
  # It's too complicated to be fixed right now (and it wouldn't add value: this is hardcoded in views, so not subject to injections)
  policy.style_src(:self, :unsafe_inline, "*.crisp.chat", "crisp.chat", 'cdn.jsdelivr.net', 'maxcdn.bootstrapcdn.com')

  connect_whitelist = ["wss://*.crisp.chat", "*.crisp.chat", "app.franceconnect.gouv.fr", "sentry.io", "openmaptiles.geo.data.gouv.fr", "openmaptiles.github.io", "tiles.geo.api.gouv.fr", "wxs.ign.fr"]
  connect_whitelist << ENV.fetch('APP_HOST')
  connect_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  connect_whitelist << URI(API_ADRESSE_URL).host if API_ADRESSE_URL.present?
  connect_whitelist << URI(API_EDUCATION_URL).host if API_EDUCATION_URL.present?
  connect_whitelist << URI(API_GEO_URL).host if API_GEO_URL.present?
  connect_whitelist << Rails.application.secrets.matomo[:host] if Rails.application.secrets.matomo[:enabled]
  policy.connect_src(:self, *connect_whitelist)

  # Frames: allow Matomo's iframe on the /suivi page
  frame_whitelist = []
  frame_whitelist << URI(MATOMO_IFRAME_URL).host if Rails.application.secrets.matomo[:enabled]
  policy.frame_src(:self, *frame_whitelist)

  # Everything else: allow us
  # Add the error source in the violation notification
  default_whitelist = ["fonts.gstatic.com", "in-automate.sendinblue.com", "player.vimeo.com", "app.franceconnect.gouv.fr", "sentry.io", "*.crisp.chat", "crisp.chat", "*.crisp.help", "*.sibautomation.com", "sibautomation.com", "data"]
  default_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  policy.default_src(:self, :data, :blob, :report_sample, *default_whitelist)

  if Rails.env.development?
    # Allow LiveReload requests
    policy.connect_src(*policy.connect_src, "ws://localhost:3035", "http://localhost:3035")

    # Allow Vite.js
    policy.connect_src(*policy.connect_src, "ws://#{ViteRuby.config.host_with_port}")
    policy.script_src(*policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}")

    # CSP are not enforced in development (see content_security_policy_report_only in development.rb)
    # However we notify a random local URL, to see breakage in the DevTools when adding a new external resource.
    policy.report_uri "http://#{ENV.fetch('APP_HOST')}/csp/"

  elsif Rails.env.test?
    # Disallow all connections to external domains during tests
    policy.img_src(:self, :data, :blob)
    policy.script_src(:self, :unsafe_eval, :unsafe_inline, :blob)
    policy.style_src(:self, :unsafe_inline)
    policy.connect_src(:self)
    policy.frame_src(:self)
    policy.default_src(:self, :data, :blob)

  else
    policy.report_uri CSP_REPORT_URI if CSP_REPORT_URI.present?
  end
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
