class GeojsonService
  def self.to_json_polygon coordinates
    polygon = {
        geo: {
            type: "Polygon",
            coordinates: [coordinates]
        }
    }

    polygon.to_json
  end
end