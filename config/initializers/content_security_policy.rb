# rubocop:disable DS/ApplicationName
Rails.application.config.content_security_policy do |policy|
  # Whitelist image
  policy.img_src :self, "*.openstreetmap.org", "static.#{FR_SITE}", "*.cloud.ovh.net", "*", :data, :blob
  # Whitelist JS: nous, sendinblue et matomo
  # miniprofiler et nous avons quelques boutons inline :(
  policy.script_src :self, "stats.data.gouv.fr", "*.sendinblue.com", "*.crisp.chat", "crisp.chat", "beta.mes-demarches.gov.pf", "*.sibautomation.com", "sibautomation.com", 'cdn.jsdelivr.net', 'maxcdn.bootstrapcdn.com', 'code.jquery.com', :unsafe_eval, :unsafe_inline, :blob
  # Pour les CSS, on a beaucoup de style inline et quelques balises <style>
  # c'est trop compliqué pour être rectifié immédiatement (et sans valeur ajoutée:
  # c'est hardcodé dans les vues, donc pas injectable).
  policy.style_src :self, "*.crisp.chat", "crisp.chat", 'cdn.jsdelivr.net', 'maxcdn.bootstrapcdn.com', :unsafe_inline
  policy.connect_src :self, "wss://*.crisp.chat", "*.crisp.chat", "*.demarches-simplifiees.fr", "in-automate.sendinblue.com", "app.franceconnect.gouv.fr", "sentry.io", "geo.api.gouv.fr", "api-adresse.data.gouv.fr", "openmaptiles.geo.data.gouv.fr", "openmaptiles.github.io", "tiles.geo.api.gouv.fr", "wxs.ign.fr", "data.education.gouv.fr"
  # Pour tout le reste, par défaut on accepte uniquement ce qui vient de chez nous
  # et dans la notification on inclue la source de l'erreur
  policy.default_src :self, :data, :blob, :report_sample, "fonts.gstatic.com", "in-automate.sendinblue.com", "player.vimeo.com", "app.franceconnect.gouv.fr", "sentry.io", "static.demarches-simplifiees.fr", "*.crisp.chat", "crisp.chat", "*.crisp.help", "*.sibautomation.com", "sibautomation.com", "data"
  if Rails.env.development?
    # Les CSP ne sont pas appliquées en dev: on notifie cependant une url quelconque de la violation
    # pour détecter les erreurs lors de l'ajout d'une nouvelle brique externe durant le développement
    # policy.report_uri "http://#{ENV['APP_HOST']}/csp/"
    # En développement, quand bin/webpack-dev-server est utilisé, on autorise les requêtes faites par le live-reload
    policy.connect_src(*policy.connect_src, "ws://localhost:3035", "http://localhost:3035")
  end
  # polynesian configurations
  policy.img_src(*policy.img_src, "beta.mes-demarches.gov.pf")
  policy.connect_src(*policy.connect_src, "www.tefenua.gov.pf", "oos.eu-west-2.outscale.com")
  policy.default_src(*policy.default_src, "oos.eu-west-2.outscale.com")
end
# rubocop:enable DS/ApplicationName
