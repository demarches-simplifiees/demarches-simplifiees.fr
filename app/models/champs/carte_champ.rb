class Champs::CarteChamp < Champ
  # We are not using scopes here as we want to access
  # the following collections on unsaved records.
  def cadastres
    geo_areas.select do |area|
      area.source == GeoArea.sources.fetch(:cadastre)
    end
  end

  def quartiers_prioritaires
    geo_areas.select do |area|
      area.source == GeoArea.sources.fetch(:quartier_prioritaire)
    end
  end

  def parcelles_agricoles
    geo_areas.select do |area|
      area.source == GeoArea.sources.fetch(:parcelle_agricole)
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
      lon = "2.428462"
      lat = "46.538192"
      zoom = "13"

      { lon: lon, lat: lat, zoom: zoom }
    end
  end

  def geo_json
    @geo_json ||= value.blank? ? nil : JSON.parse(value)
  end

  def user_geometry
    # We used to store in the value column a json array with coordinates.
    if geo_json.is_a?(Array)
      # If it is a coordinates array, format it as a GEO-JSON
      GeojsonService.to_json_polygon_for_selection_utilisateur(geo_json)
    else
      # It is already a GEO-JSON
      geo_json
    end
  end

  def user_geo_area
    if geo_json.present?
      GeoArea.new(
        geometry: user_geometry,
        source: GeoArea.sources.fetch(:selection_utilisateur)
      )
    end
  end
end
