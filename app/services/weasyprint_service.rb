# frozen_string_literal: true

class WeasyprintService
  def self.generate_pdf(html, options = {})
    headers = {
      'Content-Type' => 'application/json',
      'X-Request-Id' => Current.request_id,
    }

    body = {
      html:,
      upstream_context: options,
    }.to_json

    response = Typhoeus.post(WEASYPRINT_URL, headers:, body:)

    if response.success?
      response.body
    else
      raise StandardError, "PDF Generation failed: #{response.code} #{response.status_message}"
    end
  end
end
