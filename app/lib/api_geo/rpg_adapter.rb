class ApiGeo::RPGAdapter
  def initialize(coordinates)
    @coordinates = GeojsonService.to_json_polygon_for_rpg(coordinates)
  end

  def data_source
    @data_source ||= ApiGeo::API.search_rpg(@coordinates)
  end

  def results
    data_source[:features].map do |feature|
      feature[:properties]
        .stringify_keys
        .transform_keys(&:underscore)
        .symbolize_keys
        .slice(
          :culture,
          :code_culture,
          :surface,
          :bio
        ).merge({ geometry: feature[:geometry] })
    end
  end
end
