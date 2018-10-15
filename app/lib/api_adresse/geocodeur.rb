module ApiAdresse
  class Geocodeur
    def self.convert_adresse_to_point(address)
      ApiAdresse::PointRetriever.new(address).point
    rescue RestClient::Exception, JSON::ParserError => e
      Rails.logger.error(e.message)
      nil
    end
  end
end
