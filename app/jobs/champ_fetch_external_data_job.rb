# frozen_string_literal: true

class ChampFetchExternalDataJob < ApplicationJob
  discard_on ActiveJob::DeserializationError
  queue_as :critical # ui feedback, asap

  def perform(champ, external_id)
    return if champ.external_id != external_id

    Sentry.set_tags(champ: champ.id)
    Sentry.set_extras(external_id:)

    champ.fetch!
  end
end
