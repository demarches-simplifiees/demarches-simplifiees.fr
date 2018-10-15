class ApiAdresse::Geocodeur
  def self.convert_adresse_to_point(address)
    ApiAdresse::PointAdapter.new(address).geocode
  rescue RestClient::Exception, JSON::ParserError => e
    Rails.logger.error(e.message)
    nil
  end
end
