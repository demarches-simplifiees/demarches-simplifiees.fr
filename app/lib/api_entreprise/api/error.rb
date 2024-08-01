# frozen_string_literal: true

class APIEntreprise::API::Error < ::StandardError
  def initialize(response)
    # use uri to avoid sending token
    uri = URI.parse(response.effective_url)

    msg = <<~TEXT
      url: #{uri.host}#{uri.path}
      HTTP error code: #{response.code}
      body: #{response.body}
      curl message: #{response.return_message}
      total time: #{response.total_time}
      connect time: #{response.connect_time}
      response headers: #{response.headers}
    TEXT

    super(msg)
  end

  def network_error?
    true
  end
end
