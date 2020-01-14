Rails.application.config.content_security_policy do |policy|
  if Rails.env.development?
    # les CSP ne sont pas appliquées en dev: on notifie cependant une url quelconque de la violation
    # pour détecter les erreurs lors de l'ajout d'une nouvelle brique externe durant le développement
    policy.report_uri "http://#{ENV['APP_HOST']}/csp/"
  end
  # Whitelist image
  policy.img_src :self, "*.openstreetmap.org", "static.demarches-simplifiees.fr", "*.cloud.ovh.net", "stats.data.gouv.fr", "*", :data
  # Whitelist JS: nous, sendinblue et matomo
  # miniprofiler et nous avons quelques boutons inline :(
  policy.script_src :self, "stats.data.gouv.fr", "*.sendinblue.com", "*.crisp.chat", "crisp.chat", "*.sibautomation.com", "sibautomation.com", :unsafe_eval, :unsafe_inline, :blob
  # Pour les CSS, on a beaucoup de style inline et quelques balises <style>
  # c'est trop compliqué pour être rectifié immédiatement (et sans valeur ajoutée:
  # c'est hardcodé dans les vues, donc pas injectable).
  policy.style_src :self, "*.crisp.chat", "crisp.chat", :unsafe_inline
  policy.connect_src :self, "wss://*.crisp.chat", "*.crisp.chat", "*.demarches-simplifiees.fr", "in-automate.sendinblue.com", "app.franceconnect.gouv.fr", "sentry.io", "geo.api.gouv.fr", "api-adresse.data.gouv.fr"
  # Pour tout le reste, par défaut on accepte uniquement ce qui vient de chez nous
  # et dans la notification on inclue la source de l'erreur
  policy.default_src :self, :data, :report_sample, "fonts.gstatic.com", "in-automate.sendinblue.com", "player.vimeo.com", "app.franceconnect.gouv.fr", "sentry.io", "static.demarches-simplifiees.fr", "*.crisp.chat", "crisp.chat", "*.crisp.help", "*.sibautomation.com", "sibautomation.com", "data"
end
