class Champs::CarteChamp < Champ
  has_many :geo_areas, foreign_key: :champ_id, dependent: :destroy

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

  def cadastres?
    type_de_champ&.cadastres && type_de_champ.cadastres != '0'
  end

  def quartiers_prioritaires?
    type_de_champ&.quartiers_prioritaires && type_de_champ.quartiers_prioritaires != '0'
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

  def zones
    value.blank? ? [] : JSON.parse(value)
  end
end
