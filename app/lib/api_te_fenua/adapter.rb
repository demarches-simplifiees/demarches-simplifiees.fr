# frozen_string_literal: true

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
    if response.success?
      result = JSON.parse(response.body, symbolize_names: true)
      result[:content][:hits][:hits]
    else
      @blank_return
    end
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

  TIMEOUT = 10

  def self.search(search)
    search_url = [API_TE_FENUA_URL, "recherche"].join("/")
    Typhoeus.get(search_url, timeout: TIMEOUT, params: {
      # mandatory but unused parameters
      d: '0',
      x: '0',
      y: '0',
      id: '',
      sid: 'reqId',
      # query
      q: search
    })
  end
end
