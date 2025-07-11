# frozen_string_literal: true

module ReferentielMappingUtils
  SUPPORTED_SIMPLE_TYPES = [String, Integer, Float, NilClass].freeze

  def self.array_of_supported_simple_types?(arr)
    arr.is_a?(Array) && arr.all? { |v| SUPPORTED_SIMPLE_TYPES.any? { |type| v.is_a?(type) } }
  end

  def self.geojson_object?(value)
    return false unless value.is_a?(Hash)
    type = value["type"] || value[:type]
    %w[Point MultiPoint LineString MultiLineString Polygon MultiPolygon GeometryCollection Feature FeatureCollection].include?(type)
  end
end
