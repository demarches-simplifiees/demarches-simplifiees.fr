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

  def identify(email, attributes = {})
    req = api_request('identify', email: email, attributes: attributes)
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
    @hydra ||= Typhoeus::Hydra.new
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

  def api_request(path, body)
    url = "#{SENDINBLUE_API_URL}/#{path}"

    Typhoeus::Request.new(
      url,
      method: :post,
      body: body.to_json,
      headers: headers
    )
  end

  def headers
    {
      'ma-key': client_key,
      'Content-Type': 'application/json; charset=UTF-8'
    }
  end

  def client_key
    Rails.application.secrets.sendinblue[:client_key]
  end
end
