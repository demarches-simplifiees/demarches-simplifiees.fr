if Rails.env.production?
  API_ENTREPRISE_URL = 'https://entreprise.api.gouv.fr/v2'
else
  API_ENTREPRISE_URL = 'https://staging.entreprise.api.gouv.fr/v2'
end

PIPEDRIVE_API_URL = 'https://api.pipedrive.com/v1'
