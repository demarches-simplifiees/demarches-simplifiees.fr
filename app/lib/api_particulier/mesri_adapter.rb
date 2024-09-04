# frozen_string_literal: true

class APIParticulier::MesriAdapter
  class InvalidSchemaError < ::StandardError
    def initialize(errors)
      super(errors.map(&:to_json).join("\n"))
    end
  end

  def initialize(api_particulier_token, ine, requested_sources)
    @api = APIParticulier::API.new(api_particulier_token)
    @ine = ine
    @requested_sources = requested_sources
  end

  def to_params
    @api.etudiants(@ine)
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
    @schemer ||= JSONSchemer.schema(Rails.root.join('app/schemas/etudiants.json'))
  end

  def extract_requested_sources(data)
    @requested_sources['mesri']&.map do |(scope, sources)|
      case scope
      when 'inscriptions'
        { scope => data[scope].filter_map { |d| d.slice(*sources) if d.key?('dateDebutInscription') } }
      when 'admissions'
        { scope => data['inscriptions'].filter_map { |d| d.slice(*sources) if d.key?('dateDebutAdmission') } }
      when 'etablissements'
        { scope => data['inscriptions'].map { |d| d['etablissement'].slice(*sources) }.uniq }
      else
        { scope => data.slice(*sources) }
      end
    end
      &.flatten&.reduce(&:deep_merge) || {}
  end
end
