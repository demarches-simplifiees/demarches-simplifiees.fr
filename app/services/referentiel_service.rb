# frozen_string_literal: true

class ReferentielService
  def test
    case referentiel
    when Referentiels::APIReferentiel
      @service.valid?(referentiel.test_data)
    else
      fail "not yet implemented: #{referentiel.referentiel_adapter}"
    end
  end

  private

  attr_reader :referentiel, :service

  def initialize(referentiel:)
    @referentiel = referentiel
    @service = make_service(referentiel:)
  end

  def make_service(referentiel:) = ReferentielApiClient.new(referentiel:)

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
        referentiel.update(last_response: data.body)
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
