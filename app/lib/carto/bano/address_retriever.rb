module Carto
  module Bano
    # input : address
    # output : Array List label address
    class AddressRetriever
      def initialize(address)
        @address = address
      end

      def list
        @list ||= convert_driver_result_to_full_address
      end

      private

      def driver
        @driver ||= Carto::Bano::Driver.new @address, 5
      end

      def convert_driver_result_to_full_address
        result = JSON.parse(driver.call)

        if result['features'].size == 0
          Rails.logger.error "unable to find location for address #{@address}"
          return []
        end

        result['features'].map do |feature|
          feature['properties']['label']
        end
      rescue TypeError, JSON::ParserError
        []
      end
    end
  end
end
