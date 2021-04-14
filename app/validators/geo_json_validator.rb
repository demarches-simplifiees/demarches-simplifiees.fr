class GeoJSONValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      RGeo::GeoJSON.decode(value.to_json, geo_factory: RGeo::Geographic.spherical_factory)
    rescue RGeo::Error::InvalidGeometry
      record.errors[attribute] << (options[:message] || "n'est pas un GeoJSON valide")
    end
  end
end
