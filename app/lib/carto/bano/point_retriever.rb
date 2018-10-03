module Carto
  module Bano
    # input : address
    # output : point RGeo::Cartesian::PointImpl
    class PointRetriever
      def initialize(address)
        @address = address
      end

      def point
        @point ||= convert_driver_result_to_point
      end

      private

      def driver
        @driver ||= Carto::Bano::Driver.new @address
      end

      def convert_driver_result_to_point
        result = JSON.parse(driver.call)
        if result['features'].empty?
          Rails.logger.error "unable to find location for address #{@address}"
          return nil
        end
        RGeo::GeoJSON.decode(result['features'][0]['geometry'], json_parser: :json)
      end
    end
  end
end
