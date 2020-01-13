class ApiAdresse::Adapter
  private

  def initialize(address, limit, blank_return)
    @address = address
    @limit = limit
    @blank_return = blank_return
  end

  def features
    @features ||= get_features
  end

  def get_features
    response = ApiAdresse::API.call(@address, @limit)
    result = JSON.parse(response)
    result['features']
  rescue RestClient::Exception, JSON::ParserError, TypeError
    @blank_return
  end

  def handle_result
    if features.present?
      process_features
    else
      @blank_return
    end
  end

  def process_features
    raise NoMethodError
  end
end
