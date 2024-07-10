class APIEntreprise::PfAPI
  # as of 09/08/2023, i-taiete seems to timeout if we provide bearer token
  # ==> as i-taiete works without, bear token is no longer sent

  ENTREPRISE_RESOURCE_NAME = "etablissements/Entreprise"

  TIMEOUT = 15

  def entreprise(no_tahiti)
    call(ENTREPRISE_RESOURCE_NAME, no_tahiti)
  end

  def self.api_up?
    (200...500).cover?(Typhoeus.get(API_ISPF_URL, timeout: 2, ssl_verifypeer: false, verbose: false).code)
  end

  private

  def call(resource_name, no_tahiti)
    url = url(resource_name)
    params = params(no_tahiti)
    @typhoeus_cache ||= Typhoeus::Cache::SuccessfulRequestsRailsCache.new

    parse_response_body(Typhoeus.get(url, headers: headers, params: params, timeout: TIMEOUT, ssl_verifypeer: false, verbose: true,
    cache: @typhoeus_cache,
    cache_ttl: 1.day))
  end

  def url(resource_name)
    base_url = [API_ISPF_URL, resource_name].join("/")

    base_url
  end

  def params(no_tahiti)
    {
      numeroTahiti: no_tahiti
    }
  end

  def headers
    @header ||= {
      'X-Gravitee-Api-Key': Rails.application.secrets.api_ispf_entreprise[:gravitee],
      'Content-Type': 'application/json; charset=UTF-8'
    }
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
end
