if Rails.env.production?
  API_ENTREPRISE_URL = 'https://entreprise.api.gouv.fr/v2'
else
  API_ENTREPRISE_URL = 'https://staging.entreprise.api.gouv.fr/v2'
end

PIPEDRIVE_API_URL = 'https://api.pipedrive.com/v1/'
PIPEDRIVE_PEOPLE_URL = URI.join(PIPEDRIVE_API_URL, 'persons').to_s
PIPEDRIVE_DEALS_URL = URI.join(PIPEDRIVE_API_URL, 'deals').to_s
