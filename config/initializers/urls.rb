if Rails.env.production?
  SIADEURL = 'https://entreprise.api.gouv.fr'
else
  SIADEURL = 'https://staging.entreprise.api.gouv.fr'
end

CGU_URL = "https://demarches-simplifiees.gitbooks.io/demarches-simplifiees/content/conditions-generales-dutilisation.html"
