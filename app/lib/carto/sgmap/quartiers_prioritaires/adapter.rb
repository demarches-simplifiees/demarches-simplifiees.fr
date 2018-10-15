class CARTO::SGMAP::QuartiersPrioritaires::Adapter
  def initialize(coordinates)
    @coordinates = GeojsonService.to_json_polygon_for_qp(coordinates)
  end

  def data_source
    @data_source ||= JSON.parse(CARTO::SGMAP::API.search_qp(@coordinates), symbolize_names: true)
  end

  def to_params
    data_source[:features].map do |feature|
      feature[:properties].merge({ geometry: feature[:geometry] })
    end
  end
end
