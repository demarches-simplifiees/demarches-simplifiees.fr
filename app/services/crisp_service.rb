# frozen_string_literal: true

class CrispService
  include Dry::Monads[:result]

  HOST = 'https://api.crisp.chat'
  ENDPOINTS = {
    # https://docs.crisp.chat/references/rest-api/v1/#update-people-data
    "people_data" => '/v1/website/%{website_id}/people/data/%{email}'
  }.freeze

  def update_people_data(email:, body:)
    endpoint = format(ENDPOINTS.fetch('people_data'), website_id:, email:)
    url = build_url(endpoint)

    result = call(url:, json: body, method: :patch)

    case result
    in Success(body:)
      Success(body)
    in Failure(code:, reason:)
      Failure(API::Client::Error[:api_error, code, false, reason])
    end
  end

  private

  def website_id = ENV.fetch("CRISP_WEBSITE_ID")
  def client_identifier = ENV.fetch("CRISP_CLIENT_IDENTIFIER")
  def client_key = ENV.fetch("CRISP_CLIENT_KEY")

  def call(url:, json: nil, method: :get)
    API::Client.new.call(
      url:,
      json:,
      method:,
      headers:,
      basic_auth:
    )
  end

  def headers
    {
      'X-Crisp-Tier' => 'Plugin'
    }
  end

  def basic_auth
    {
      username: client_identifier,
      password: client_key
    }
  end

  def build_url(endpoint)
    uri = URI(HOST)
    uri.path = endpoint
    uri
  end
end
