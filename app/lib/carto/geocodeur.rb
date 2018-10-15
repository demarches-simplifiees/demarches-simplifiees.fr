module Carto
  # this class take a string in input and return a point
  class Geocodeur
    def self.convert_adresse_to_point(address)
      ApiAdresse::PointRetriever.new(address).point
    rescue RestClient::Exception, JSON::ParserError => e
      Rails.logger.error e.message
      nil
    end
  end
end
