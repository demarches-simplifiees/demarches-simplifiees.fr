class APICartoService
  def self.generate_qp(coordinates)
    coordinates.flat_map do |coordinate|
      APICarto::QuartiersPrioritairesAdapter.new(
        coordinate.map { |element| [element['lng'], element['lat']] }
      ).results
    end
  end

  def self.generate_cadastre(coordinates)
    coordinates.flat_map do |coordinate|
      APICarto::CadastreAdapter.new(
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
end
