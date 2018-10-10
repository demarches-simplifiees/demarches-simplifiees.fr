class CARTO::SGMAP::ParcellesAgricoles::Adapter
  def initialize(coordinates)
    @coordinates = GeojsonService.to_json_polygon_for_qp(coordinates)
  end

  def data_source
    @data_source ||= JSON.parse(CARTO::SGMAP::API.search_pa(@coordinates), symbolize_names: true)
  end

  def to_params
    params = {}

    data_source[:features].each do |feature|
      pa_code = feature[:properties][:code]

      params[pa_code] = feature[:properties]
      params[pa_code][:geometry] = feature[:geometry]
    end

    params
  end
end
