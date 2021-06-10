# frozen_string_literal: true

module APIParticulier
  class API
    def initialize(**kwargs)
      attrs = kwargs.symbolize_keys
      @api_url = attrs[:api_url]
      @token = attrs[:token]
      @timeout = attrs[:timeout]
      @http_service = attrs[:http_service]
    end

    def composition_familiale(numero_d_allocataire:, code_postal:)
      params = { numeroAllocataire: numero_d_allocataire, codePostal: code_postal }

      get("composition-familiale", **params) do |response|
        data = JSON.parse(response.body, symbolize_names: true)
        APIParticulier::Entities::CAF::Famille.new(**data)
      end
    end

    def introspect
      get("../introspect") do |response|
        data = JSON.parse(response.body, symbolize_names: true)
        APIParticulier::Entities::Introspection.new(**data)
      end
    end

    def ping?
      get("../ping") { true }
    rescue Error::HttpError
      false
    end

    private

    attr_reader :token

    def http_service
      @http_service || Typhoeus::Request
    end

    def api_url
      @api_url || Rails.configuration.x.api_particulier.url
    end

    def timeout
      @timeout.to_i || Rails.configuration.x.api_particulier.timeout
    end

    def headers
      { accept: "application/json", "X-API-Key": token }
    end

    def get(base_url, **params, &block)
      url = [api_url, base_url].join("/")
      request = http_service.new(url, headers: headers, method: :get, params: params, timeout: timeout)

      request.on_complete do |response|
        if response.success?
          return yield response
        elsif response.timed_out?
          raise Error::TimedOut.new(response)
        elsif response.code == 400
          raise Error::BadFormatRequest.new(response)
        elsif response.code == 401
          raise Error::Unauthorized.new(response)
        elsif response.code == 404
          raise Error::NotFound.new(response)
        elsif response.code == 502
          raise	Error::BadGateway.new(response)
        elsif response.code == 503
          raise Error::ServiceUnavailable.new(response)
        else
          raise Error::RequestFailed.new(response)
        end
      end

      request.run
    end
  end
end
