class GeojsonService
  def self.to_json_polygon_for_cadastre(coordinates)
    polygon = {
      geom: {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [
            coordinates
          ]
        }
      }
    }

    polygon.to_json
  end
end
