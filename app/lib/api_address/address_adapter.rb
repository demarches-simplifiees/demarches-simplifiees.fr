require 'json_schemer'

class APIAddress::AddressAdapter
  class InvalidSchemaError < ::StandardError
    def initialize(errors)
      super(errors.map(&:to_json).join("\n"))
    end
  end

  def initialize(search_term)
    @search_term = search_term
  end

  def to_params
    result = Geocoder.search(@search_term, limit: 1).first
    if result.present? && result.national_address == @search_term
      feature = result.data['features'].first
      if schemer.valid?(feature)
        {
          label: result.national_address,
          type: result.result_type,
          street_address: result.street_address,
          street_number: result.street_number,
          street_name: result.street_name,
          postal_code: result.postal_code,
          city_name: result.city_name,
          city_code: result.city_code,
          department_name: result.department_name,
          department_code: result.department_code,
          region_name: result.region_name,
          region_code: result.region_code,
          geometry: result.geometry
        }
      else
        errors = schemer.validate(feature).to_a
        raise InvalidSchemaError.new(errors)
      end
    end
  end

  private

  def schemer
    @schemer ||= JSONSchemer.schema(Rails.root.join('app/schemas/adresse-ban.json'))
  end
end
