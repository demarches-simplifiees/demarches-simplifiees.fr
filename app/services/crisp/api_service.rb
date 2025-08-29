# frozen_string_literal: true

module Crisp
  class APIService
    include Dry::Monads[:result]

    HOST = 'https://api.crisp.chat'
    ENDPOINTS = {
      # https://docs.crisp.chat/references/rest-api/v1/#update-people-data
      "people_data" => '/v1/website/%{website_id}/people/data/%{email}',
      # https://docs.crisp.chat/references/rest-api/v1/#create-a-new-conversation
      "create_conversation" => '/v1/website/%{website_id}/conversation',
      # https://docs.crisp.chat/references/rest-api/v1/#send-a-message-in-conversation
      "send_message" => '/v1/website/%{website_id}/conversation/%{session_id}/message',
      # https://docs.crisp.chat/references/rest-api/v1/#update-conversation-metas
      "update_conversation_meta" => '/v1/website/%{website_id}/conversation/%{session_id}/meta'
    }.freeze

    def update_people_data(email:, body:)
      endpoint = format(ENDPOINTS['people_data'], website_id:, email:)
      url = build_url(endpoint)

      result = call(url:, json: body, method: :patch)
      handle_result(result)
    end

    def create_conversation
      endpoint = format(ENDPOINTS['create_conversation'], website_id:)
      url = build_url(endpoint)

      result = call(url:, json: {}, method: :post)
      handle_result(result)
    end

    def send_message(session_id:, body:)
      endpoint = format(ENDPOINTS['send_message'], website_id:, session_id:)
      url = build_url(endpoint)

      result = call(url:, json: body, method: :post)
      handle_result(result)
    end

    def update_conversation_meta(session_id:, body:)
      endpoint = format(ENDPOINTS['update_conversation_meta'], website_id:, session_id:)
      url = build_url(endpoint)

      result = call(url:, json: body, method: :patch)
      handle_result(result)
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
        userpwd: "#{client_identifier}:#{client_key}"
      )
    end

    def headers
      {
        'X-Crisp-Tier' => 'plugin'
      }
    end

    def build_url(endpoint)
      uri = URI(HOST)
      uri.path = endpoint
      uri
    end

    def handle_result(result)
      case result
      in Success(body:)
        Success(body)
      in Failure(code:, reason:)
        Failure(API::Client::Error[:api_error, code, false, reason])
      end
    end
  end
end
