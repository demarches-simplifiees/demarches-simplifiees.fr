class ApiAdresse::AddressAdapter
  def initialize(address)
    @address = address
  end

  def get_suggestions
    @list ||= convert_api_result_to_full_address
  end

  private

  def convert_api_result_to_full_address
    result = JSON.parse(ApiAdresse::API.call(@address, 5))

    if result['features'].empty?
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
