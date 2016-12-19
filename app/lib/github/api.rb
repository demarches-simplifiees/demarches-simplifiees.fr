class Github::API

  def self.base_uri
    'https://api.github.com'
  end

  def self.latest_release
    call '/repos/sgmap/tps/releases/latest'
  end

  private

  def self.call(end_point, params = {})
    RestClient::Resource.new(
        base_uri+end_point, timeout: 5
    ).get(params: params)
  rescue RestClient::Forbidden
    nil
  end
end
