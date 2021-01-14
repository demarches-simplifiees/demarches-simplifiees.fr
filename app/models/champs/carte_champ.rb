# == Schema Information
#
# Table name: champs
#
#  id               :integer          not null, primary key
#  data             :jsonb
#  private          :boolean          default(FALSE), not null
#  row              :integer
#  type             :string
#  value            :string
#  created_at       :datetime
#  updated_at       :datetime
#  dossier_id       :integer
#  etablissement_id :integer
#  external_id      :string
#  parent_id        :bigint
#  type_de_champ_id :integer
#
class Champs::CarteChamp < Champ
  # Default map location. Center of the World, ahm, France...
  DEFAULT_LON = 2.428462
  DEFAULT_LAT = 46.538192

  # We are not using scopes here as we want to access
  # the following collections on unsaved records.
  def cadastres
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:cadastre)
    end
  end

  def selections_utilisateur
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:selection_utilisateur)
    end
  end

  def layer_enabled?(layer)
    type_de_champ.options && type_de_champ.options[layer] && type_de_champ.options[layer] != '0'
  end

  def cadastres?
    layer_enabled?(:cadastres)
  end

  def optional_layers
    [
      :unesco,
      :arretes_protection,
      :conservatoire_littoral,
      :reserves_chasse_faune_sauvage,
      :reserves_biologiques,
      :reserves_naturelles,
      :natura_2000,
      :zones_humides,
      :znieff,
      :cadastres
    ].map do |layer|
      layer_enabled?(layer) ? layer : nil
    end.compact
  end

  def render_options
    {
      ign: Flipper.enabled?(:carte_ign, procedure),
      layers: optional_layers
    }
  end

  def position
    if dossier.present?
      dossier.geo_position
    else
      lon = DEFAULT_LON.to_s
      lat = DEFAULT_LAT.to_s
      zoom = "13"

      { lon: lon, lat: lat, zoom: zoom }
    end
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

  def geometry?
    geo_areas.present?
  end

  def selection_utilisateur_legacy_geo_area
    geometry = selection_utilisateur_legacy_geometry
    if geometry.present?
      GeoArea.new(
        source: GeoArea.sources.fetch(:selection_utilisateur),
        geometry: geometry
      )
    end
  end

  def for_api
    nil
  end

  def for_export
    nil
  end

  private

  def selection_utilisateur_legacy_geometry
    if selections_utilisateur.present?
      {
        type: 'MultiPolygon',
        coordinates: selections_utilisateur.filter do |selection_utilisateur|
          selection_utilisateur.geometry['type'] == 'Polygon'
        end.map do |selection_utilisateur|
          selection_utilisateur.geometry['coordinates']
        end
      }
    else
      nil
    end
  end
end
