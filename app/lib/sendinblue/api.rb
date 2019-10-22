class Sendinblue::Api
  def self.new_properly_configured!
    api = self.new
    if !api.properly_configured?
      raise StandardError, 'Sendinblue API is not properly configured'
    end
    api
  end

  def initialize
    @failures = []
  end

  def properly_configured?
    client_key.present?
  end

  def update_contact(email, attributes = {})
    req = post_api_request('contacts', email: email, attributes: attributes, updateEnabled: true)
    req.on_complete do |response|
      if !response.success?
        push_failure("Error while updating identity for administrateur '#{email}' in Sendinblue: #{response.response_code} '#{response.body}'")
      end
    end
    hydra.queue(req)
  end

  def run
    hydra.run
    @hydra = nil
    flush_failures
  end

  private

  def hydra
    @hydra ||= Typhoeus::Hydra.new(max_concurrency: 50)
  end

  def push_failure(failure)
    @failures << failure
  end

  def flush_failures
    failures = @failures
    @failures = []
    if failures.present?
      raise StandardError, failures.join(', ')
    end
  end

  def post_api_request(path, body)
    url = "#{SENDINBLUE_API_V3_URL}/#{path}"

    Typhoeus::Request.new(
      url,
      method: :post,
      body: body.to_json,
      headers: headers
    )
  end

  def headers
    {
      'api-key': client_key,
      'Content-Type': 'application/json; charset=UTF-8'
    }
  end

  def client_key
    Rails.application.secrets.sendinblue[:api_v3_key]
  end
end
