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

  # The following code is ported from turfjs
  # https://github.com/Turfjs/turf/blob/master/packages/turf-area/index.ts

  EQUATORIAL_RADIUS = 6378137

  def self.area(geojson)
    calculate_area(geojson)
  end

  def self.calculate_area(geom)
    total = 0
    case geom[:type]
    when 'Polygon'
      polygon_area(geom[:coordinates]);
    when 'MultiPolygon'
      geom[:coordinates].each do |coordinates|
        total += polygon_area(coordinates)
      end
      total
    else
      total
    end
  end

  def self.polygon_area(coordinates)
    total = 0
    if coordinates.present?
      coordinates = coordinates.dup
      total += ring_area(coordinates.shift).abs
      coordinates.each do |coordinates|
        total -= ring_area(coordinates).abs
      end
    end
    total
  end

  def self.ring_area(coordinates)
    total = 0
    coords_length = coordinates.size

    if coords_length > 2
      coords_length.times do |i|
        if i == coords_length - 2 # i = N-2
          lower_index = coords_length - 2
          middle_index = coords_length - 1
          upper_index = 0
        elsif i == coords_length - 1 # i = N-1
          lower_index = coords_length - 1
          middle_index = 0
          upper_index = 1
        else # i = 0 to N-3
          lower_index = i
          middle_index = i + 1
          upper_index = i + 2
        end
        p1 = coordinates[lower_index]
        p2 = coordinates[middle_index]
        p3 = coordinates[upper_index]
        total += (rad(p3[0]) - rad(p1[0])) * Math.sin(rad(p2[1]))
      end
      total = total * EQUATORIAL_RADIUS * EQUATORIAL_RADIUS / 2
    end

    total
  end

  def self.rad(num)
    num * Math::PI / 180
  end
end
