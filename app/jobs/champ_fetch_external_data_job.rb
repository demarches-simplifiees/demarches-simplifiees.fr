class ChampFetchExternalDataJob < ApplicationJob
  include Dry::Monads[:result]

  def perform(champ, external_id)
    Rails.logger.info("ChampFetchExternalDataJob : external_id = #{external_id}, attributes = #{champ.attributes}")
    Rails.logger.info("cancel as external ids are different #{champ.external_id} != #{external_id}") if champ.external_id != external_id
    return if champ.external_id != external_id
    Rails.logger.info("cancel as data is present #{champ.data}") if champ.data.present?
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
