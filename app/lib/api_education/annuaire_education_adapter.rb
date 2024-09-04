# frozen_string_literal: true

require 'json_schemer'

class APIEducation::AnnuaireEducationAdapter
  class InvalidSchemaError < ::StandardError
    def initialize(errors)
      super(errors.map(&:to_json).join("\n"))
    end
  end

  def initialize(id)
    @id = id
  end

  def to_params
    record = data_source[:records].first
    if record.present?
      properties = record[:fields].merge({ geometry: record[:geometry] }).deep_stringify_keys
      # API sends numbers as strings sometime. Try to parse.
      if properties['code_type_contrat_prive'].is_a? String
        code = properties['code_type_contrat_prive'].to_i
        if code.to_s == properties['code_type_contrat_prive']
          properties['code_type_contrat_prive'] = code
        end
      end
      if schemer.valid?(properties)
        properties
      else
        errors = schemer.validate(properties).to_a
        raise InvalidSchemaError.new(errors)
      end
    end
  end

  private

  def data_source
    @data_source ||= JSON.parse(APIEducation::API.get_annuaire_education(@id), symbolize_names: true)
  end

  def schemer
    @schemer ||= JSONSchemer.schema(Rails.root.join('app/schemas/etablissement-annuaire-education.json'))
  end
end
