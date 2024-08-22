# frozen_string_literal: true

class APIParticulier::CnafAdapter
  class InvalidSchemaError < ::StandardError
    def initialize(errors)
      super(errors.map(&:to_json).join("\n"))
    end
  end

  def initialize(api_particulier_token, numero_allocataire, code_postal, requested_sources)
    @api = APIParticulier::API.new(api_particulier_token)
    @numero_allocataire = numero_allocataire
    @code_postal = code_postal
    @requested_sources = requested_sources
  end

  def to_params
    @api.composition_familiale(@numero_allocataire, @code_postal)
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
    @schemer ||= JSONSchemer.schema(Rails.root.join('app/schemas/composition-familiale.json'))
  end

  def extract_requested_sources(data)
    @requested_sources['cnaf']&.map do |(scope, sources)|
      case scope
      when 'enfants', 'allocataires'
        { scope => data[scope].map { |s| s.slice(*sources) } }
      when 'quotient_familial'
        { scope => data.slice(*sources) }
      else
        { scope => data[scope].slice(*sources) }
      end
    end
      &.reduce(&:deep_merge) || {}
  end
end
