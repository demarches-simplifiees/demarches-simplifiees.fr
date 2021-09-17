class APIParticulier::API
  include APIParticulier::Error

  INTROSPECT_RESOURCE_NAME = "introspect"
  COMPOSITION_FAMILIALE_RESOURCE_NAME = "v2/composition-familiale"

  TIMEOUT = 20

  def initialize(token)
    @token = token
  end

  def scopes
    get(INTROSPECT_RESOURCE_NAME)['scopes']
  end

  def composition_familiale(numero_allocataire, code_postal)
    get(COMPOSITION_FAMILIALE_RESOURCE_NAME,
                   numeroAllocataire: numero_allocataire,
                   codePostal: code_postal)
  end

  private

  def get(resource_name, params = {})
    url = [API_PARTICULIER_URL, resource_name].join("/")

    response = Typhoeus.get(url,
      headers: { accept: "application/json", "X-API-Key": @token },
      params: params,
      timeout: TIMEOUT)

    if response.success?
      JSON.parse(response.body)
    elsif response.code == 401
      raise Unauthorized.new(response)
    else
      raise RequestFailed.new(response)
    end
  end
end
