# frozen_string_literal: true

class OCRService
  include Dry::Monads[:result]

  def self.analyze(blob)
    url = ENV.fetch("OCR_SERVICE_URL", nil)

    return if url.nil? # Service is not enabled

    blob_url = blob.url
    json = { "url": blob_url, "hint": { "type": "rib" } }
    headers = { 'X-Remote-File': blob_url } # needed for logging

    result = API::Client.new.call(url:, method: :post, headers:, json:)

    case result
    in Success(body:)
      body
    in Failure(code:, reason:)
      { error: { code:, message: reason.message } }
    end
  rescue StandardError => e
    if Rails.env.development?
      raise e # In development, raise the error to see it in the console
    else
      Sentry.capture_exception(e, extra: { blob_url: blob_url })
    end
  end
end
