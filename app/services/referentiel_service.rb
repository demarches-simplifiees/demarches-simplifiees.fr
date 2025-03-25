# frozen_string_literal: true

class ReferentielService
  include Dry::Monads[:result]

  RETRYABLE_STATUS_CODES = [429, 500, 503, 408, 502].freeze
  NON_RETRYABLE_STATUS_CODES = [404, 400, 403, 401].freeze

  attr_reader :referentiel, :service

  def initialize(referentiel:)
    @referentiel = referentiel
  end

  def call(query_params)
    result = API::Client.new.call(url: referentiel.url.gsub('{id}', query_params))

    case result
    in Success(body:)
      Success(body)
    in Failure(code:) if code.in?(NON_RETRYABLE_STATUS_CODES) # search may not have been found
      Failure(retryable: false, reason: StandardError.new('Not retryable: 404, 400, 403, 401'), code:)
    in Failure(code:) if code.in?(RETRYABLE_STATUS_CODES) # api may be rate limited, or down etc..
      Failure(retryable: true, reason: StandardError.new('Retryable: 429, 500, 503, 408, 502'), code:)
    in Failure
      Failure(retryable: false, reason: StandardError.new('Unknown error'), code:)
    end
  end

  def test
    case referentiel
    when Referentiels::APIReferentiel
      result = call(referentiel.test_data)
      case result
      in Success(body)
        referentiel.update_column(:last_response, { status: 200, body: })
        true
      in Failure(data)
        referentiel.update_column(:last_response, { status: data[:code], body: data[:body] })
        false
      end
    end
  end
end
