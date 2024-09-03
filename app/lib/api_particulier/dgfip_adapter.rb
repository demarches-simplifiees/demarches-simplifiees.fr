# frozen_string_literal: true

class APIParticulier::DgfipAdapter
  class InvalidSchemaError < ::StandardError
    def initialize(errors)
      super(errors.map(&:to_json).join("\n"))
    end
  end

  def initialize(api_particulier_token, numero_fiscal, reference_avis, requested_sources)
    @api = APIParticulier::API.new(api_particulier_token)
    @numero_fiscal = numero_fiscal
    @reference_avis = reference_avis
    @requested_sources = requested_sources
  end

  def to_params
    @api.avis_imposition(@numero_fiscal, @reference_avis)
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
    @schemer ||= JSONSchemer.schema(Rails.root.join('app/schemas/avis-imposition.json'))
  end

  def extract_requested_sources(data)
    @requested_sources['dgfip']&.map do |(scope, sources)|
      case scope
      when 'foyer_fiscal'
        { scope => data['foyerFiscal'].slice(*sources).merge(data.slice(*sources)) }
      when 'declarant1', 'declarant2'
        sources.map { |source| { scope => data[scope].slice(*source) } }
      when 'agregats_fiscaux', 'echeance_avis', 'complements'
        sources.map { |source| { scope => data.slice(*source) } }
      else
        { scope => data.slice(*sources) }
      end
    end
      &.flatten&.reduce(&:deep_merge) || {}
  end
end
