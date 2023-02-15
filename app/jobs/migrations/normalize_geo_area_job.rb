class Migrations::NormalizeGeoAreaJob < ApplicationJob
  def perform(ids)
    GeoArea.where(id: ids).find_each do |geo_area|
      geojson = RGeo::GeoJSON.decode(geo_area.geometry.to_json, geo_factory: RGeo::Geographic.simple_mercator_factory)
      geometry = RGeo::GeoJSON.encode(geojson)
      geo_area.update_column(:geometry, geometry)
    rescue RGeo::Error::InvalidGeometry
      geo_area.destroy
    end
  end
end
