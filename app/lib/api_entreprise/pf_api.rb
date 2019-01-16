class ApiEntreprise::PF_API
  ENTREPRISE_RESOURCE_NAME = "etablissementsEntreprise"

  TIMEOUT = 15

  def self.entreprise(no_tahiti)
    call(ENTREPRISE_RESOURCE_NAME, no_tahiti)
  end

  private

  def self.call(resource_name, no_tahiti)
    url = url(resource_name)
    params = params(no_tahiti)

    response = Typhoeus.get(url, params: params, timeout: TIMEOUT, ssl_verifypeer: false, verbose: true, userpwd: user_password)

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    else

      raise RestClient::ResourceNotFound
    end
  end

  def self.url(resource_name)
    base_url = [API_ENTREPRISE_PF_URL, resource_name].join("/")

    base_url
  end

  def self.params(no_tahiti)
    {
      numeroTahiti: no_tahiti
    }
  end

  def self.user_password
    [Rails.application.secrets.api_ispf_entreprise[:user], Rails.application.secrets.api_ispf_entreprise[:pwd]].join(':')
  end
end
