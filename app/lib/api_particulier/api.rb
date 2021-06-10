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

    def avis_d_imposition(numero_fiscal:, reference_de_l_avis:)
      # NOTE: Attention, il est possible que l'utilisateur ajoute une quatorzième lettre à la fin de sa
      # référence d'avis. Il s'agit d'une clé de vérification, il est nécessaire de l'enlever avant de
      # l'envoyer sur l'API Particulier.
      params = {
        numeroFiscal: numero_fiscal.to_i.to_s.rjust(13, "0"),
        referenceAvis: reference_de_l_avis.to_i.to_s.rjust(13, "0")
      }

      get("avis-imposition", **params) do |response|
        data = JSON.parse(response.body, symbolize_names: true)
        APIParticulier::Entities::DGFIP::AvisImposition.new(**data)
      end
    end

    def composition_familiale(numero_d_allocataire:, code_postal:)
      params = { numeroAllocataire: numero_d_allocataire, codePostal: code_postal }

      get("composition-familiale", **params) do |response|
        data = JSON.parse(response.body, symbolize_names: true)
        APIParticulier::Entities::CAF::Famille.new(**data)
      end
    end

    def situation_pole_emploi(identifiant:)
      params = { identifiant: identifiant }

      get("situations-pole-emploi", **params) do |response|
        data = JSON.parse(response.body, symbolize_names: true)
        APIParticulier::Entities::PoleEmploi::SituationPoleEmploi.new(**data)
      end
    end

    def etudiants(ine:)
      params = { ine: ine }

      get("etudiants", **params) do |response|
        data = JSON.parse(response.body, symbolize_names: true)
        APIParticulier::Entities::MESRI::Etudiant.new(**data)
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
