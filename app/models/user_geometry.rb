class UserGeometry
  alias :read_attribute_for_serialization :send

  def initialize(json_latlngs)
    @json_latlngs = json_latlngs
  end

  def geometry
    to_geo_json(@json_latlngs)
  end

  def type_de_champ
    {
      id: -1,
      libelle: 'user_geometry',
      type_champ: 'user_geometry',
      order_place: -1,
      descripton: ''
    }
  end

  private

  def to_geo_json(json_latlngs)
    json = JSON.parse(json_latlngs)

    coordinates = json.map do |lat_longs|
      outbounds = lat_longs.map do |lat_long|
        [lat_long['lng'], lat_long['lat']]
      end

      [outbounds]
    end

    {
      type: 'MultiPolygon',
      coordinates: coordinates
    }
  end
end
