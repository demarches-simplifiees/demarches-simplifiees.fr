# frozen_string_literal: true

module ActiveJob::RetryOnTransientErrors
  extend ActiveSupport::Concern

  TRANSIENT_ERRORS = [
    Excon::Error::InternalServerError,
    Excon::Error::GatewayTimeout,
    Excon::Error::BadRequest,
    Excon::Error::Socket
  ]

  included do
    if handler_for_rescue(TRANSIENT_ERRORS.first).nil?
      TRANSIENT_ERRORS.each do |error_type|
        retry_on error_type, attempts: 5, wait: :exponentially_longer
      end
    end
  end
end
