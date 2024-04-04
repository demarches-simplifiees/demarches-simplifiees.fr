class DeliverWebhookJob < ApplicationJob
  class RetryableError < StandardError
  end

  queue_as :webhooks_v2
  discard_on ActiveRecord::RecordNotFound
  retry_on RetryableError, wait: :exponentially_longer, attempts: 13

  def perform(webhook, event)
    data = {
      event_id: event.to_typed_id,
      webhook_id: webhook.to_typed_id,
      enqueued_at: event.enqueued_at.iso8601
    }

    if webhook.deliver(data) == :error
      raise RetryableError
    end
  end
end
