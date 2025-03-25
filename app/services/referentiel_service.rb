# frozen_string_literal: true

class ReferentielService
  include Dry::Monads[:result]

  attr_reader :referentiel, :service

  def initialize(referentiel:)
    @referentiel = referentiel
  end

  def call(query_params)
    result = API::Client.new.call(url: referentiel.url.gsub('{id}', query_params))

    case result
    in Success(body:)
      Success(body)
    in Failure
      result
    end
  end

  def test
    case referentiel
    when Referentiels::APIReferentiel
      result = call(referentiel.test_data)

      case result
      in Success(body)
        referentiel.update(last_response: { status: 200, body: })
        true
      in Failure(data)
        referentiel.update(last_response: { status: data.code, body: data.try(:body) })
        false
      end
    end
  end
end
