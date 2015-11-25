class CARTO::SGMAP::QuartierPrioritaireAdapter
  def initialize(coordinates)
    @coordinates = GeojsonService.to_json_polygon(coordinates)
  end

  def data_source
    @data_source ||= JSON.parse(CARTO::SGMAP::API.search_qp(@coordinates), symbolize_names: true)
  end

  def to_params
    params = {}

    data_source[:features].each_with_index do |feature, index|
      qp_code = feature[:properties][:code]

      params[qp_code] = feature[:properties]
      params[qp_code][:geometry] = feature[:geometry]
    end

    params
  end

  def properties_to_fetch
    [:code,
     :nom,
     :commune]
  end
end
