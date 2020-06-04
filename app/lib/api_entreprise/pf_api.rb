class ApiEntreprise::PF_API
  ENTREPRISE_RESOURCE_NAME = "etablissements/Entreprise"

  TIMEOUT = 15

  def entreprise(no_tahiti)
    call(ENTREPRISE_RESOURCE_NAME, no_tahiti)
  end

  private

  def call(resource_name, no_tahiti)
    url = url(resource_name)
    params = params(no_tahiti)

    response = Typhoeus.get(url, params: params, timeout: TIMEOUT, ssl_verifypeer: false, verbose: false, headers: headers)

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    elsif response.code&.between?(401, 499)
      raise ApiEntreprise::API::ResourceNotFound
    else
      raise ApiEntreprise::API::RequestFailed
    end
  end

  def url(resource_name)
    base_url = [API_ENTREPRISE_PF_URL, resource_name].join("/")

    base_url
  end

  def params(no_tahiti)
    {
      numeroTahiti: no_tahiti
    }
  end

  def headers
    {
      'Authorization': "Bearer #{access_token}",
      'Content-Type': 'application/json; charset=UTF-8'
    }
  end

  def access_token
    if !@expires_at || Time.zone.now >= @expires_at
      body = parse_response_body(fetch_access_token)
      if (body[:error])
        Rails.logger.error "Unable to connect to I-taiete : #{body[:error_description]}"
        puts "Unable to connect to i-taiete : #{body[:error_description]}"
        return ''
      end
      @access_token = body[:access_token]
      @expires_at = Time.zone.now + body[:expires_in].seconds - 1.minute
    end
    @access_token
  end

  def parse_response_body(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def user_password
    [Rails.application.secrets.api_ispf_entreprise[:user], Rails.application.secrets.api_ispf_entreprise[:pwd]].join(':')
  end

  def fetch_access_token
    Typhoeus.post(API_ENTREPRISE_PF_AUTH, body: { grant_type: 'client_credentials' }, userpwd: user_password)
  end
end
