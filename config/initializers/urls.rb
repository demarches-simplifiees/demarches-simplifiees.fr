if Rails.env.production?
  SIADEURL = 'https://entreprise.api.gouv.fr'
else
  SIADEURL = 'https://staging.entreprise.api.gouv.fr'
end
