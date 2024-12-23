# frozen_string_literal: true

class ReferentielService
  def test
    case referentiel
    when Referentiels::APIReferentiel
      ReferentielApiClient.new(referentiel:).valid?(referentiel.test_data)
    else
      fail "not yet implemented: #{referentiel.referentiel_adapter}"
    end
  end

  private

  attr_reader :referentiel
  def initialize(referentiel:)
    @referentiel = referentiel
  end

  class ReferentielApiClient
    include Dry::Monads[:result]

    attr_reader :referentiel
    def initialize(referentiel:)
      @referentiel = referentiel
    end

    def valid?(value)
      result = call(value)
      case result
      in Success(data)
        referentiel.update(last_response: data)
      else
        false
      end
    end

    def call(value) = API::Client.new.(url: build_url(value))

    def build_url(value)
      original_url = @referentiel.url

      original_url.gsub('{id}', value)
    end
  end
end
