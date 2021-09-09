# == Schema Information
#
# Table name: geo_areas
#
#  id               :bigint           not null, primary key
#  geometry         :jsonb
#  properties       :jsonb
#  source           :string
#  created_at       :datetime
#  updated_at       :datetime
#  champ_id         :bigint
#  geo_reference_id :string
#
class GeoArea < ApplicationRecord
  belongs_to :champ, optional: false

  store :properties, accessors: [
    :description,
    :surface_intersection,
    :surface_parcelle,
    :numero,
    :feuille,
    :section,
    :code_dep,
    :nom_com,
    :code_com,
    :code_arr,
    :code,
    :nom,
    :commune,
    :culture,
    :code_culture,
    :surface,
    :bio
  ]

  enum source: {
    cadastre: 'cadastre',
    selection_utilisateur: 'selection_utilisateur'
  }

  scope :selections_utilisateur, -> { where(source: sources.fetch(:selection_utilisateur)) }
  scope :cadastres, -> { where(source: sources.fetch(:cadastre)) }

  validates :geometry, geo_json: true, allow_blank: false

  def to_feature
    {
      type: 'Feature',
      geometry: safe_geometry,
      properties: properties.symbolize_keys.merge(
        source: source,
        area: area,
        length: length,
        id: id,
        champ_id: champ.stable_id,
        dossier_id: champ.dossier_id
      ).compact
    }
  end

  def safe_geometry
    RGeo::GeoJSON.encode(rgeo_geometry)
  end

  def rgeo_geometry
    RGeo::GeoJSON.decode(geometry.to_json, geo_factory: RGeo::Geographic.simple_mercator_factory)
  rescue RGeo::Error::InvalidGeometry
    nil
  end

  def self.from_feature_collection(feature_collection)
    feature_collection[:features].map do |feature|
      GeoArea.new(
        source: feature[:properties].delete(:source),
        properties: feature[:properties],
        geometry: feature[:geometry]
      )
    end
  end

  def area
    if polygon?
      GeojsonService.area(geometry.deep_symbolize_keys).round(1)
    end
  end

  def length
    if line?
      GeojsonService.length(geometry.deep_symbolize_keys).round(1)
    end
  end

  def location
    if point?
      Geo::Coord.new(*rgeo_geometry.coordinates.reverse).to_s
    end
  end

  def line?
    geometry['type'] == 'LineString'
  end

  def polygon?
    geometry['type'] == 'Polygon'
  end

  def point?
    geometry['type'] == 'Point'
  end
end
