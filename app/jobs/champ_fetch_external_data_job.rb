# frozen_string_literal: true

class ChampFetchExternalDataJob < ApplicationJob
  discard_on ActiveJob::DeserializationError
  queue_as :critical # ui feedback, asap

  def perform(champ, external_id)
    return if champ.external_id != external_id
    return if champ.data.present?

    Sentry.set_tags(champ: champ.id)
    Sentry.set_extras(external_id:)

    result = champ.fetch_external_data
    champ.handle_result(result, champ)
  end
end
