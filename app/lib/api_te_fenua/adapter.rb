class APITeFenua::Adapter
  private

  def initialize(address, blank_return)
    @address = address
    @blank_return = blank_return
  end

  def features
    @features ||= get_features
  end

  def get_features
    response = self.class.search(@address)
    result = JSON.parse(response, symbolize_names: true)
    result[:content]
  rescue RestClient::Exception, JSON::ParserError, TypeError
    @blank_return
  end

  def handle_result
    if @address.length < 4
      @blank_return
    elsif features.present?
      process(features)
    else
      @blank_return
    end
  end

  def process(features)
    raise NoMethodError
  end

  def self.search(search)
    search_url = [API_TE_FENUA_URL, "recherche"].join("/")
    RestClient::Request.execute(method: :get,
                                url: search_url,
                                timeout: 8,
                                headers: {
                                  params: {
                                    # mandatory but unused parameters
                                    d: '0',
                                    x: '0',
                                    y: '0',
                                    id: '',
                                    sid: 'reqId',
                                    # query
                                    q: search
                                  }
                                })
  rescue RestClient::ServiceUnavailable
    nil
  rescue StandardError => e
    puts e.message
    puts e.backtrace
    nil
  end
end
