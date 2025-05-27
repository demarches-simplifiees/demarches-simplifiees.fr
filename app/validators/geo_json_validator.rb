# frozen_string_literal: true

class GeoJSONValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if options[:allow_nil] == false && value.nil?
      record.errors.add(attribute, :blank, message: options[:message] || "ne peut pas être vide")
    end

    unless value.blank? || GeojsonService.valid_schema?(value)
      record.errors.add(attribute, :invalid_geometry, message: options[:message] || "n'est pas un GeoJSON valide")
    end

    unless value.blank? || GeojsonService.valid_wgs84_coordinates?(value)
      record.errors.add(attribute, :invalid_geometry, message: options[:message] || "contient des coordonnées invalides, veuillez utiliser le système de coordonnées WGS84")
    end
  end
end
