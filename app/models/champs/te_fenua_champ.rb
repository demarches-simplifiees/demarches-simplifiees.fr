# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::TeFenuaChamp < Champ
  # We are not using scopes here as we want to access
  # the following collections on unsaved records.

  def parcelles
    geo_json_from_value[:parcelles][:features]
  end

  def batiments
    geo_json_from_value[:batiments][:features]
  end

  def zones_manuelles
    geo_json_from_value[:zones_manuelles][:features]
  end

  def parcelles?
    type_de_champ&.parcelles && type_de_champ.parcelles != '0'
  end

  def batiments?
    type_de_champ&.batiments && type_de_champ.batiments != '0'
  end

  def zones_manuelles?
    type_de_champ&.zones_manuelles && type_de_champ.zones_manuelles != '0'
  end

  def position
    geo_json_from_value[:position]
  end

  def entry
    result = [];
    if parcelles? then
      result << 'parcelles'
    end
    if batiments? then
      result << 'batiments'
    end
    if zones_manuelles? then
      result << 'zones_manuelles'
    end
    result.join(',')
  end

  def to_render_data
    {
      position: position,
      batiments: batiments? ? batiments : [],
      cadastres: parcelles? ? parcelles : [],
      zones_manuelles: zones_manuelles? ? zones_manuelles : []
    }
  end

  def bounding_box
    factory = RGeo::Geographic.simple_mercator_factory
    bounding_box = RGeo::Cartesian::BoundingBox.new(factory)

    if geo_areas.present?
      geo_areas.map(&:rgeo_geometry).compact.each do |geometry|
        bounding_box.add(geometry)
      end
    elsif dossier.present?
      point = dossier.geo_position
      bounding_box.add(factory.point(point[:lon], point[:lat]))
    else
      bounding_box.add(factory.point(DEFAULT_LON, DEFAULT_LAT))
    end

    [bounding_box.max_point, bounding_box.min_point].compact.flat_map(&:coordinates)
  end

  def to_feature_collection
    {
      type: 'FeatureCollection',
      id: stable_id,
      bbox: bounding_box,
      features: geo_areas.map(&:to_feature)
    }
  end

  def geo_json_from_value
    @geo_json_from_value ||= begin
      parsed_value = value.blank? ? nil : JSON.parse(value, symbolize_names: true)
      # We used to store in the value column a json array with coordinates.
      if parsed_value.is_a?(Array)
        # Empty array is sent instead of blank to distinguish between empty and error
        if parsed_value.empty?
          nil
        else
          # If it is a coordinates array, format it as a GEO-JSON
          JSON.parse(GeojsonService.to_json_polygon_for_selection_utilisateur(parsed_value))
        end
      else
        # It is already a GEO-JSON
        parsed_value
      end
    end
  end

  def for_api
    nil
  end

  def for_export
    nil
  end
end
