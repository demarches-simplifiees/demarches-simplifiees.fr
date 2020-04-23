class GeoArea < ApplicationRecord
  belongs_to :champ

  store :properties, accessors: [
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
    quartier_prioritaire: 'quartier_prioritaire',
    cadastre: 'cadastre',
    parcelle_agricole: 'parcelle_agricole',
    selection_utilisateur: 'selection_utilisateur'
  }

  scope :selections_utilisateur, -> { where(source: sources.fetch(:selection_utilisateur)) }
  scope :quartiers_prioritaires, -> { where(source: sources.fetch(:quartier_prioritaire)) }
  scope :cadastres, -> { where(source: sources.fetch(:cadastre)) }
  scope :parcelles_agricoles, -> { where(source: sources.fetch(:parcelle_agricole)) }

  def to_feature
    {
      type: 'Feature',
      geometry: geometry,
      properties: properties.merge(source: source, area: area, length: length).compact
    }
  end

  def rgeo_geometry
    RGeo::GeoJSON.decode(geometry.to_json, geo_factory: RGeo::Geographic.simple_mercator_factory)
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
    if polygon? && RGeo::Geos.supported?
      rgeo_geometry.area.round(1)
    end
  end

  def length
    if line? && RGeo::Geos.supported?
      rgeo_geometry.length.round(1)
    end
  end

  def location
    if point?
      Geo::Coord.new(*rgeo_geometry.coordinates).to_s
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
