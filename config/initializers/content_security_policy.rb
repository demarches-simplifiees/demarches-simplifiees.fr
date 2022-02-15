# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  # Whitelist image
  images_whitelist = ["*.openstreetmap.org", "*.cloud.ovh.net", "*"]
  images_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  images_whitelist << URI(MATOMO_IFRAME_URL).host if MATOMO_IFRAME_URL.present?
  policy.img_src(:self, :data, :blob, *images_whitelist)

  # Whitelist JS: nous, sendinblue et matomo
  # miniprofiler et nous avons quelques boutons inline :(
  scripts_whitelist = ["*.sendinblue.com", "*.crisp.chat", "crisp.chat", "*.sibautomation.com", "sibautomation.com", "cdn.jsdelivr.net", "maxcdn.bootstrapcdn.com", "code.jquery.com"]
  scripts_whitelist << URI(MATOMO_IFRAME_URL).host if MATOMO_IFRAME_URL.present?
  policy.script_src(:self, :unsafe_eval, :unsafe_inline, :blob, *scripts_whitelist)

  # Pour les CSS, on a beaucoup de style inline et quelques balises <style>
  # c'est trop compliqué pour être rectifié immédiatement (et sans valeur ajoutée:
  # c'est hardcodé dans les vues, donc pas injectable).
  policy.style_src(:self, "*.crisp.chat", "crisp.chat", 'cdn.jsdelivr.net', 'maxcdn.bootstrapcdn.com', :unsafe_inline)

  connect_whitelist = ["wss://*.crisp.chat", "*.crisp.chat", "in-automate.sendinblue.com", "app.franceconnect.gouv.fr", "sentry.io", "openmaptiles.geo.data.gouv.fr", "openmaptiles.github.io", "tiles.geo.api.gouv.fr", "wxs.ign.fr"]
  connect_whitelist << ENV.fetch('APP_HOST')
  connect_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  connect_whitelist << URI(API_ADRESSE_URL).host if API_ADRESSE_URL.present?
  connect_whitelist << URI(API_EDUCATION_URL).host if API_EDUCATION_URL.present?
  connect_whitelist << URI(API_GEO_URL).host if API_GEO_URL.present?
  connect_whitelist << Rails.application.secrets.matomo[:host] if Rails.application.secrets.matomo[:enabled]
  policy.connect_src(:self, *connect_whitelist)

  # Pour tout le reste, par défaut on accepte uniquement ce qui vient de chez nous
  # et dans la notification on inclue la source de l'erreur
  default_whitelist = ["fonts.gstatic.com", "in-automate.sendinblue.com", "player.vimeo.com", "app.franceconnect.gouv.fr", "sentry.io", "*.crisp.chat", "crisp.chat", "*.crisp.help", "*.sibautomation.com", "sibautomation.com", "data"]
  default_whitelist << URI(DS_PROXY_URL).host if DS_PROXY_URL.present?
  policy.default_src(:self, :data, :blob, :report_sample, *default_whitelist)

  if Rails.env.development?
    # Les CSP ne sont pas appliquées en dev: on notifie cependant une url quelconque de la violation
    # pour détecter les erreurs lors de l'ajout d'une nouvelle brique externe durant le développement
    policy.report_uri "http://#{ENV.fetch('APP_HOST')}/csp/"
    # En développement, quand bin/webpack-dev-server est utilisé, on autorise les requêtes faites par le live-reload
    policy.connect_src(*policy.connect_src, "ws://localhost:3035", "http://localhost:3035")
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
