class CARTO::SGMAP::Cadastre::Adapter
  def initialize(coordinates)
    @coordinates = GeojsonService.to_json_polygon_for_cadastre(coordinates)
  end

  def data_source
    @data_source ||= JSON.parse(CARTO::SGMAP::API.search_cadastre(@coordinates), symbolize_names: true)
  end

  def to_params
    params = []

    data_source[:features].each do |feature|
      tmp = feature[:properties]
      tmp[:geometry] = feature[:geometry]

      params << tmp
    end

    params
  end
end
