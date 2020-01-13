class ApiAdresse::AddressAdapter < ApiAdresse::Adapter
  def initialize(address)
    super(address, 5, [])
  end

  def get_suggestions
    handle_result
  end

  private

  def process_features
    features.map do |feature|
      feature['properties']['label']
    end
  end
end
