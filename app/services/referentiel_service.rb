# frozen_string_literal: true

class ReferentielService
  include Dry::Monads[:result]

  attr_reader :referentiel, :service

  def initialize(referentiel:)
    @referentiel = referentiel
  end

  def test
    case referentiel
    when Referentiels::APIReferentiel
      result = API::Client.new.call(url: referentiel.url.gsub('{id}', referentiel.test_data))

      case result
      in Success(data)
        referentiel.update(last_response: { status: 200, body: data.body })
        true
      in Failure(data)
        referentiel.update(last_response: { status: data.code, body: data.try(:body) })
        false
      end
    else
      fail "not yet implemented: #{referentiel.type}"
    end
  end
end
