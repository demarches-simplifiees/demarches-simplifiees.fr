class ApiAdresse::PointAdapter < ApiAdresse::Adapter
  def initialize(address)
    super(address, 1, nil)
  end

  def geocode
    handle_result
  end

  private

  def process_features
    RGeo::GeoJSON.decode(features[0]['geometry'], json_parser: :json)
  end
end
