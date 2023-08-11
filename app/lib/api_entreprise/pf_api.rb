class APIEntreprise::PfAPI
  # as of 09/08/2023, i-taiete seems to timeout if we provide bearer token
  # ==> as i-taiete works without, bear token is no longer sent

  ENTREPRISE_RESOURCE_NAME = "etablissements/Entreprise"

  TIMEOUT = 15

  def entreprise(no_tahiti)
    call(ENTREPRISE_RESOURCE_NAME, no_tahiti)
  end

  def self.api_up?
    (200...500).cover?(Typhoeus.get(API_ENTREPRISE_PF_URL, timeout: 2, ssl_verifypeer: false, verbose: false).code)
  end

  private

  def call(resource_name, no_tahiti)
    url = url(resource_name)
    params = params(no_tahiti)

    parse_response_body(Typhoeus.get(url, params: params, timeout: TIMEOUT, ssl_verifypeer: false, verbose: false))
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
        raise APIEntreprise::API::Error::ServiceUnavailable.new(response)
      end
      @access_token = body[:access_token]
      @expires_at = Time.zone.now + body[:expires_in].seconds - 1.minute
    end
    @access_token
  end

  def parse_response_body(response)
    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    elsif response.code&.between?(401, 499)
      raise APIEntreprise::API::Error::ResourceNotFound.new(response)
    elsif response.code == 400
      raise APIEntreprise::API::Error::BadFormatRequest.new(response)
    elsif response.code == 502
      raise APIEntreprise::API::Error::BadGateway.new(response)
    elsif response.code == 503
      raise APIEntreprise::API::Error::ServiceUnavailable.new(response)
    elsif response.timed_out?
      raise APIEntreprise::API::Error::TimedOut.new(response)
    else
      raise APIEntreprise::API::Error::RequestFailed.new(response)
    end
  end

  def user_password
    [Rails.application.secrets.api_ispf_entreprise[:user], Rails.application.secrets.api_ispf_entreprise[:pwd]].join(':')
  end

  def fetch_access_token
    Typhoeus.post(API_ENTREPRISE_PF_AUTH, body: { grant_type: 'client_credentials' }, userpwd: user_password)
  end
end
