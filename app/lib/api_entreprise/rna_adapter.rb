require 'json_schemer'

class APIEntreprise::RNAAdapter < APIEntreprise::Adapter
  class InvalidSchemaError < ::StandardError
    def initialize(errors)
      super(errors.map(&:to_json).join("\n"))
    end
  end

  private

  def get_resource
    api(@procedure_id).rna(@siret)
  end

  def process_params
    params = data_source[:association]

    Sentry.with_scope do |scope|
      scope.set_tags(siret: @siret)
      scope.set_extras(source: params)

      params = params&.slice(*attr_to_fetch) if @depreciated
      params[:rna] = data_source.dig(:association, :id)

      if params[:rna].present? && valid_params?(params)
        params = params.transform_keys { |k| :"association_#{k}" }.deep_stringify_keys

        raise InvalidSchemaError.new(schemer.validate(params).to_a) unless schemer.valid?(params)

        params
      else
        {}
      end
    end
  end

  def schemer
    @schemer ||= JSONSchemer.schema(Rails.root.join('app/schemas/association.json'))
  end

  def attr_to_fetch
    [
      :titre,
      :objet,
      :date_creation,
      :date_declaration,
      :date_publication
    ]
  end
end
