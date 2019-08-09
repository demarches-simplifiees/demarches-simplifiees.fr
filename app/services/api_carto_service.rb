class ApiCartoService
  def self.generate_qp(coordinates)
    coordinates.flat_map do |coordinate|
      ApiCarto::QuartiersPrioritairesAdapter.new(
        coordinate.map { |element| [element['lng'], element['lat']] }
      ).results
    end
  end

  def self.generate_cadastre(coordinates)
    coordinates.flat_map do |coordinate|
      ApiCarto::CadastreAdapter.new(
        coordinate.map { |element| [element['lng'], element['lat']] }
      ).results
    end
  end

  def self.generate_rpg(coordinates)
    coordinates.flat_map do |coordinate|
      ApiGeo::RPGAdapter.new(
        coordinate.map { |element| [element['lng'], element['lat']] }
      ).results
    end
  end

  def self.generate_selection_utilisateur(coordinates)
    {
      geometry: JSON.parse(GeojsonService.to_json_polygon_for_selection_utilisateur(coordinates))
    }
  end
end
