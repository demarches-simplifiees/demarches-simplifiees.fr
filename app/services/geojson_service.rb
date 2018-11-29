class GeojsonService
  def self.to_json_polygon_for_qp(coordinates)
    polygon = {
      geo: {
        type: "Polygon",
        coordinates: [coordinates]
      }
    }

    polygon.to_json
  end

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

  def self.to_json_polygon_for_rpg(coordinates)
    polygon = {
      polygonIntersects: {
        type: "Polygon",
        coordinates: [coordinates]
      }
    }

    polygon.to_json
  end

  def self.to_json_polygon_for_selection_utilisateur(coordinates)
    coordinates = coordinates.map do |lat_longs|
      outbounds = lat_longs.map do |lat_long|
        [lat_long['lng'], lat_long['lat']]
      end

      [outbounds]
    end

    polygon = {
      type: 'MultiPolygon',
      coordinates: coordinates
    }

    polygon.to_json
  end
end
