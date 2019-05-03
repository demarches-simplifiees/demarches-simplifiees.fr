Rails.application.config.content_security_policy do |policy|
  # En cas de non respect d'une des règles, faire un POST sur cette URL
  policy.report_uri "https://e30e0ed9c14194254481124271b34a72.report-uri.com/r/d/csp/reportOnly"
  # Whitelist image
  policy.img_src :self, "https://*.openstreetmap.org"
  # Whitelist JS: nous, sendinblue et matomo, et… miniprofiler :(
  if Rails.env.development?
    # https://github.com/MiniProfiler/rack-mini-profiler/issues/327
    policy.script_src :self, "https://sibautomation.com", "//stats.data.gouv.fr", :unsafe_eval, :unsafe_inline
  else
    policy.script_src :self, "https://sibautomation.com", "//stats.data.gouv.fr"
  end
  # Génération d'un nonce pour les balises script inline qu'on maitrise (Gon)
  Rails.application.config.content_security_policy_nonce_generator = -> _request { SecureRandom.base64(16) }

  # Pour les CSS, on a beaucoup de style inline et quelques balises <style>
  # c'est trop compliqué pour être rectifié immédiatement (et sans valeur ajoutée:
  # c'est hardcodé dans les vues, donc pas injectable).
  policy.style_src :self, :unsafe_inline
  # Pour tout le reste, par défaut on accepte uniquement ce qui vient de chez nous
  # et dans la notification on inclue la source de l'erreur
  policy.default_src :self, :data, :report_sample
end
