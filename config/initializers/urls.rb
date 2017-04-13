if Rails.env.production?
  SIADEURL = 'https://api.apientreprise.fr'
else
  SIADEURL = 'https://api-dev.apientreprise.fr'
end
