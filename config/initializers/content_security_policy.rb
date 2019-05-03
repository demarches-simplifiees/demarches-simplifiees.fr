Rails.application.config.content_security_policy do |policy|
  # En cas de non respect d'une des règles, faire un POST sur cette URL
  policy.report_uri  "/csp-violation-report-endpoint"
  # Nos whitelist
  policy.img_src     :self, "https://*.openstreetmap.org"
  # sendinblue et matomo, et… miniprofiler :(
  # https://github.com/MiniProfiler/rack-mini-profiler/issues/327
  if Rails.env.development?
    #policy.script_src  :self, "https://sibautomation.com", "//stats.data.gouv.fr", :unsafe_eval, :unsafe_inline
    policy.script_src  :self, "https://sibautomation.com", "//stats.data.gouv.fr", :unsafe_eval
  else
    policy.script_src  :self, "https://sibautomation.com", "//stats.data.gouv.fr"
  end
  # Pour les CSS, on a beaucoup de style inline et quelques balises <style>
  # c'est trop compliqué pour être rectifié immédiatement (et sans valeur ajoutée:
  # c'est hardocodé dans les vues, donc pas injectable).
  policy.style_src   :self, :unsafe_inline
  # Pour tout le reste, par défaut on accepte uniquement ce qui vient de chez nous
  # et dans la notification on inclue la source de l'erreur
  policy.default_src :self, :data, :report_sample
end