if Rails.env.production?
  SIADEURL = 'https://entreprise.api.gouv.fr/v2'
else
  SIADEURL = 'https://staging.entreprise.api.gouv.fr/v2'
end
