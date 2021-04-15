require 'json'

class APICps::API
  RESOURCE_NAME = "covid/assures/coherenceDnDdn/multiples"

  TIMEOUT = 3

  # dn_pairs must be of the form { DN ==> BirthDate }
  def verify(dn_pairs)
    call(RESOURCE_NAME, dn_pairs)
  end

  private

  def call(resource_name, dn_pairs)
    url     = url(resource_name)
    json_dn = json_dn(dn_pairs)
    response = Typhoeus.post(url, body: json_dn, timeout: TIMEOUT, ssl_verifypeer: true, verbose: false, headers: headers)

    if response.success?
      JSON.parse(response.body)['datas']
    elsif response.code&.between?(401, 499)
      raise APIEntreprise::API::Error::ResourceNotFound.new(response)
    else
      Rails.logger.error("Unable to contact CPS API: response code #{response.code} url=#{url} called with #{json_dn}")
      raise APIEntreprise::API::Error::RequestFailed.new(response)
    end
  end

  def url(resource_name)
    base_url = [API_CPS_URL, resource_name].join("/")
    base_url
  end

  def json_dn(dn_pairs)
    dn_pairs = Hash[dn_pairs.map do |dn, date|
      begin
        date = Date.parse(date) if date.is_a? String
      rescue
        date = Date.parse('01/01/1800')
      end
      if date.is_a? Date
        [dn, date.strftime('%d/%m/%Y')]
      else
        raise ArgumentError "Invalid date format " + date
      end
    end]
    {
      datas: dn_pairs
    }.to_json
  end

  def headers
    {
      'Authorization': "Bearer #{access_token}",
      'Content-Type':  'application/json'
    }
  end

  def access_token
    if !@expires_at || Time.zone.now >= @expires_at
      body = parse_response_body(fetch_access_token)
      if (body[:error])
        Rails.logger.error "Unable to connect to CPS's keycloak : #{body[:error_description]} url=#{API_CPS_AUTH}"
        return ''
      end
      @access_token = body[:access_token]
      @expires_at   = Time.zone.now + body[:expires_in].seconds - 1.minute
    end
    @access_token
  end

  def parse_response_body(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def fetch_access_token
    Typhoeus.post(API_CPS_AUTH, body: auth_body)
  end

  def auth_body
    {
      grant_type:    'password',
      client_id:     Rails.application.secrets.api_cps[:client_id],
      client_secret: Rails.application.secrets.api_cps[:client_secret],
      username:      Rails.application.secrets.api_cps[:username],
      password:      Rails.application.secrets.api_cps[:password],
      scope:         'openid'
    }
  end
end
