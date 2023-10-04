require 'dry/monads/result/fixed'

class ChampFetchExternalDataJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  include Dry::Monads[:result]

  def perform(champ, external_id)
    return if champ.external_id != external_id
    return if champ.data.present?

    Sentry.set_tags(champ: champ.id)
    Sentry.set_extras(external_id:)

    result = champ.fetch_external_data

    if result.is_a?(Dry::Monads::Result)
      case result
      in Success(data)
        champ.update_with_external_data!(data:)
      in Failure(retryable: true, reason:)
        champ.log_fetch_external_data_exception(reason)
        throw reason
      in Failure(retryable: false, reason:)
        champ.log_fetch_external_data_exception(reason)
        Sentry.capture_exception(reason)
      end
    elsif result.present?
      champ.update_with_external_data!(data: result)
    end
  end
end
