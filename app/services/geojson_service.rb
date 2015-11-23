class GeojsonService
  def self.to_polygon coordinates
    {
        geo: {
            type: "Polygon",
            coordinates: [coordinates]
        }
    }
  end
end