class APIBretagneService
  include Dry::Monads[:result]
  HOST = 'https://api.databretagne.fr'
  ENDPOINTS = {
    # see: https://api.databretagne.fr/budget/doc#operations-Auth_Controller-post_login
    "login" => "/budget/api/v1/auth/login",
    # see: https://api.databretagne.fr/budget/doc#operations-Centre_couts-get_ref_controller_list
    "centre-couts" => '/budget/api/v1/centre-couts',
    # see: https://api.databretagne.fr/budget/doc#operations-Domaine_Fonctionnel-get_ref_controller_list
    "domaine-fonct" => '/budget/api/v1/domaine-fonct',
    # see: https://api.databretagne.fr/budget/doc#operations-Referentiel_Programmation-get_ref_controller_list
    "ref-programmation" => '/budget/api/v1/ref-programmation'
  }

  def search_domaine_fonct(code_or_label: "")
    url = build_url(ENDPOINTS.fetch('domaine-fonct'))
    fetch_all_page(url:, code_or_label:)
  end

  private

  def fetch_page(url:, params:, retry_count: 1)
    result = call(url:, params:)
    case result
    in Failure(code:, reason:) if code.in?(401..403)
      if retry_count > 0
        login
        fetch_page(url:, params:, retry_count: 0)
      else
        fail "APIBretagneService, #{reason} #{code}"
      end
    in Failure(code:) if code == 204
      []
    in Success(body:)
      body
    end
  end

  def fetch_all_page(url:, code_or_label:)
    first_page = fetch_page(url:, params: { page_number: 1, query: code_or_label })
    return [] if first_page.empty?

    total_pages = (first_page[:pageInfo][:totalRows].to_f / first_page[:pageInfo][:pageSize].to_f).ceil
    all = first_page[:items]
    (2..total_pages).map do |page_number|
      page = fetch_page(url:, params: { page_number: })
      all.concat(page[:items])
    end
    all
  end

  def call(url:, params:)
    API::Client.new.(url:, params:, authorization_token:, method:)
  end

  def method
    :get
  end

  def authorization_token
    result = login
    case result
    in Success(token:)
      @token = token
    in Failure(reason:, code:)
      fail "APIBretagneService, #{reason} #{code}"
    end
  end

  def login
    result = API::Client.new.call(url: build_url(ENDPOINTS.fetch("login")),
                                  json: {
                                    email: ENV['API_DATABRETAGE_USERNAME'],
                                          password: ENV['API_DATABRETAGE_PASSWORD']
                                  },
                                  method: :post)
    case result
    in Success(body:)
      Success(token: body.split("Bearer ")[1])
    in Failure(code:, reason:) if code.in?(403)
      Failure(API::Client::Error[:invalid_credential, code, false, reason])
    else
      Failure(API::Client::Error[:api_down])
    end
  end

  def build_url(endpoint)
    uri = URI(HOST)
    uri.path = endpoint
    uri
  end
end
