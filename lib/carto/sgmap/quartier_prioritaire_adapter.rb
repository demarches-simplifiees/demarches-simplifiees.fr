class CARTO::SGMAP::QuartierPrioritaireAdapter
  def initialize(coordinates)
    @coordinates = GeojsonService.to_polygon(coordinates)
  end

  def data_source
    @data_source ||= JSON.parse(CARTO::SGMAP::API.search_qp(@coordinates), symbolize_names: true)
  end

  def to_params
    params = {}

    data_source[:features].each_with_index do |feature, index|
      params[index] = feature[:properties]
      params[index][:geometry] = feature[:geometry].to_s
    end

    params
  end

  def properties_to_fetch
    [:code,
     :nom,
     :commune]
  end
end
