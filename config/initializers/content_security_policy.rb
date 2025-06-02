# frozen_string_literal: true

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
  scripts_whitelist = ["*.crisp.chat", "crisp.chat", "cdn.jsdelivr.net", "maxcdn.bootstrapcdn.com", "code.jquery.com", "unpkg.com"]
  scripts_whitelist << URI(MATOMO_IFRAME_URL).host if MATOMO_IFRAME_URL.present?
  policy.script_src(:self, :unsafe_eval, :unsafe_inline, :blob, *scripts_whitelist)

  # CSS: We have a lot of inline style, and some <style> tags.
  # It's too complicated to be fixed right now (and it wouldn't add value: this is hardcoded in views, so not subject to injections)
  policy.style_src(:self, :unsafe_inline, "*.crisp.chat", "crisp.chat", 'cdn.jsdelivr.net', 'maxcdn.bootstrapcdn.com', "unpkg.com")

  connect_whitelist = ["wss://*.crisp.chat", "*.crisp.chat", "app.franceconnect.gouv.fr", "openmaptiles.geo.data.gouv.fr", "openmaptiles.github.io", "tiles.geo.api.gouv.fr", "data.geopf.fr"]
  connect_whitelist << ENV.fetch('APP_HOST')
  connect_whitelist << ENV.fetch('APP_HOST_LEGACY') if ENV.key?('APP_HOST_LEGACY') && ENV['APP_HOST_LEGACY'] != ENV['APP_HOST']
  connect_whitelist << "*.amazonaws.com" if Rails.configuration.active_storage.service == :amazon
  connect_whitelist += [URI(ENV["SENTRY_DSN_JS"]).host, URI(ENV["SENTRY_DSN_RAILS"]).host].compact.uniq
  connect_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  connect_whitelist << URI(API_ADRESSE_URL).host if API_ADRESSE_URL.present?
  connect_whitelist << URI(API_EDUCATION_URL).host if API_EDUCATION_URL.present?
  connect_whitelist << URI(API_GEO_URL).host if API_GEO_URL.present?
  connect_whitelist << Rails.application.secrets.matomo[:host] if Rails.application.secrets.matomo[:enabled]
  policy.connect_src(:self, *connect_whitelist)

  # Frames: allow some iframes
  frame_whitelist = []
  # allow Matomo's iframe on the /suivi page
  frame_whitelist << URI(MATOMO_IFRAME_URL).host if Rails.application.secrets.matomo[:enabled]
  # allow pdf iframes in the PJ gallery
  frame_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  policy.frame_src(:self, *frame_whitelist)

  # Everything else: allow us
  # Add the error source in the violation notification
  default_whitelist = ["fonts.gstatic.com", "in-automate.sendinblue.com", "player.vimeo.com", "app.franceconnect.gouv.fr", "*.crisp.chat", "crisp.chat", "*.crisp.help", "*.sibautomation.com", "sibautomation.com", "data"]
  default_whitelist += [URI(ENV["SENTRY_DSN_JS"]).host, URI(ENV["SENTRY_DSN_RAILS"]).host].compact.uniq
  default_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  policy.default_src(:self, :data, :blob, :report_sample, *default_whitelist)

  if Rails.env.development?
    # Allow LiveReload requests
    policy.connect_src(*policy.connect_src, "ws://localhost:3035", "http://localhost:3035")

    # Allow Vite.js
    policy.connect_src(*policy.connect_src, "ws://#{ViteRuby.config.host_with_port}")
    policy.script_src(*policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}")

  elsif Rails.env.test?
    # Disallow all connections to external domains during tests
    policy.img_src(:self, :data, :blob)
    policy.script_src(:self, :unsafe_eval, :unsafe_inline, :blob)
    policy.style_src(:self, :unsafe_inline)
    policy.connect_src(:self)
    policy.frame_src(:self)
    policy.default_src(:self, :data, :blob)
  end
  # polynesian configurations
  policy.connect_src(*policy.connect_src, "www.tefenua.gov.pf")
  if S3_ENDPOINT_URL.present?
    domain = URI(S3_ENDPOINT_URL).host
    policy.frame_src(*policy.frame_src, domain)
    policy.connect_src(*policy.connect_src, domain)
    policy.default_src(*policy.default_src, domain)
    policy.img_src(*policy.img_src, domain)
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
