class DeliverWebhookJob < ApplicationJob
  class RetryableError < StandardError
  end

  queue_as :webhooks_v2
  discard_on ActiveRecord::RecordNotFound
  retry_on RetryableError, wait: :exponentially_longer, attempts: 13

  def perform(webhook, event)
    data = {
      id: event.to_typed_id,
      date: event.enqueued_at.iso8601,
      cursor: event.cursor,
      event_type: event.event_type,
      resource_type: event.resource_type,
      resource_id: event.resource_id,
      resource_version: event.resource_version
    }

    if webhook.deliver(data) == :error
      raise RetryableError
    end
  end
end
