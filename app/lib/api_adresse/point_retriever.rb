module ApiAdresse
  class PointRetriever
    def initialize(address)
      @address = address
    end

    def point
      @point ||= convert_api_result_to_point
    end

    private

    def convert_api_result_to_point
      result = JSON.parse(ApiAdresse::API.call(@address))
      if result['features'].empty?
        Rails.logger.error "unable to find location for address #{@address}"
        return nil
      end
      RGeo::GeoJSON.decode(result['features'][0]['geometry'], json_parser: :json)
    end
  end
end
