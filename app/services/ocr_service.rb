# frozen_string_literal: true

class OCRService
  def self.analyze(blob)
    url = ENV.fetch("OCR_SERVICE_URL", nil)

    return Dry::Monads::Failure(retryable: false, reason: StandardError.new('OCR not configured')) if url.nil? # Service is not enabled

    blob_url = blob.url
    json = { "url": blob_url, "hint": { "type": "rib" } }
    headers = { 'X-Remote-File': blob_url } # needed for logging

    handle_api_result(API::Client.new.call(url:, method: :post, headers:, json:))
  end

  private

  def self.handle_api_result(result)
    case result
    in Dry::Monads::Success(body:)
      Dry::Monads::Success(body)
    in Dry::Monads::Failure(code:, reason:)
      Dry::Monads::Failure(retryable: false, reason:, code:)
    else
      Dry::Monads::Failure(retryable: false, reason: StandardError.new('Unknown error'))
    end
  end
end
