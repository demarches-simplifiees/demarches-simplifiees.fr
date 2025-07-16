# frozen_string_literal: true

class ChampFetchExternalDataJob < ApplicationJob
  discard_on ActiveJob::DeserializationError
  queue_as :critical # ui feedback, asap

  include Dry::Monads[:result]

  def perform(champ, external_id)
    return if champ.external_id != external_id
    return if champ.data.present?

    Sentry.set_tags(champ: champ.id)
    Sentry.set_extras(external_id:)

    result = champ.fetch_external_data
    handle_result(result, champ)
  end

  private

  def handle_result(result, champ)
    if result.is_a?(Dry::Monads::Result)
      case result
      in Success(data)
        champ.update_external_data!(data:)
      in Failure(retryable: true, reason:, code:)
        champ.save_external_exception(reason, code)
        raise reason
      in Failure(retryable: false, reason:, code:)
        champ.save_external_exception(reason, code)
        Sentry.capture_exception(reason)
      end
    elsif result.present?
      champ.update_external_data!(data: result)
    end
  end
end
