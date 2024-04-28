# frozen_string_literal: true

class APIParticulier::PoleEmploiAdapter
  class InvalidSchemaError < ::StandardError
    def initialize(errors)
      super(errors.map(&:to_json).join("\n"))
    end
  end

  def initialize(api_particulier_token, identifiant, requested_sources)
    @api = APIParticulier::API.new(api_particulier_token)
    @identifiant = identifiant
    @requested_sources = requested_sources
  end

  def to_params
    @api.situation_pole_emploi(@identifiant)
      .tap  { |d| ensure_valid_schema!(d) }
      .then { |d| extract_requested_sources(d) }
  end

  private

  def ensure_valid_schema!(data)
    if !schemer.valid?(data)
      errors = schemer.validate(data).to_a
      raise InvalidSchemaError.new(errors)
    end
  end

  def schemer
    @schemer ||= JSONSchemer.schema(Rails.root.join('app/schemas/situation-pole-emploi.json'))
  end

  def extract_requested_sources(data)
    @requested_sources['pole_emploi']&.map do |(scope, sources)|
      case scope
      when 'adresse'
        sources.map { |source| { scope => data[scope].slice(*source) } }
      when 'identifiant', 'contact', 'inscription'
        sources.map { |source| { scope => data.slice(*source) } }
      else
        { scope => data.slice(*sources) }
      end
    end
      &.flatten&.reduce(&:deep_merge) || {}
  end
end
