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

  def quartiers_prioritaires
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:quartier_prioritaire)
    end
  end

  def parcelles_agricoles
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:parcelle_agricole)
    end
  end

  def selections_utilisateur
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:selection_utilisateur)
    end
  end

  def cadastres?
    type_de_champ&.cadastres && type_de_champ.cadastres != '0'
  end

  def quartiers_prioritaires?
    type_de_champ&.quartiers_prioritaires && type_de_champ.quartiers_prioritaires != '0'
  end

  def parcelles_agricoles?
    type_de_champ&.parcelles_agricoles && type_de_champ.parcelles_agricoles != '0'
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
      geo_areas.each do |area|
        bounding_box.add(area.rgeo_geometry)
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
      id: type_de_champ.stable_id,
      bbox: bounding_box,
      features: (legacy_selections_utilisateur + except_selections_utilisateur).map(&:to_feature)
    }
  end

  def geometry?
    geo_areas.present?
  end

  def selection_utilisateur_legacy_geometry
    if selection_utilisateur_legacy?
      selections_utilisateur.first.geometry
    elsif selections_utilisateur.present?
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

  def selection_utilisateur_legacy_geo_area
    geometry = selection_utilisateur_legacy_geometry
    if geometry.present?
      GeoArea.new(
        source: GeoArea.sources.fetch(:selection_utilisateur),
        geometry: geometry
      )
    end
  end

  def to_render_data
    {
      position: position,
      selection: selection_utilisateur_legacy_geometry,
      quartiersPrioritaires: quartiers_prioritaires? ? quartiers_prioritaires.as_json(except: :properties) : [],
      cadastres: cadastres? ? cadastres.as_json(except: :properties) : [],
      parcellesAgricoles: parcelles_agricoles? ? parcelles_agricoles.as_json(except: :properties) : []
    }
  end

  def for_api
    nil
  end

  def for_export
    nil
  end

  private

  def selection_utilisateur_legacy?
    if selections_utilisateur.size == 1
      geometry = selections_utilisateur.first.geometry
      return geometry && geometry['type'] == 'MultiPolygon'
    end

    false
  end

  def legacy_selections_utilisateur
    if selection_utilisateur_legacy?
      selections_utilisateur.first.geometry['coordinates'].map do |coordinates|
        GeoArea.new(
          geometry: {
            type: 'Polygon',
            coordinates: coordinates
          },
          properties: {},
          source: GeoArea.sources.fetch(:selection_utilisateur)
        )
      end
    else
      selections_utilisateur
    end
  end

  def except_selections_utilisateur
    geo_areas.filter do |area|
      area.source != GeoArea.sources.fetch(:selection_utilisateur)
    end
  end
end
