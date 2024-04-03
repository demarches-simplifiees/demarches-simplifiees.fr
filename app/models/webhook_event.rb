class WebhookEvent < ApplicationRecord
  belongs_to :webhook

  scope :delivered, -> { joins(:webhook).where('enqueued_at < webhooks.last_success_at') }
  scope :expired, -> { where(enqueued_at: ..2.weeks.ago) }

  enum event_types: Webhook::EVENT_TYPES

  def cursor
    cursor_parts = [enqueued_at.utc.strftime("%Y-%m-%dT%H:%M:%S.%NZ"), id].join(';')
    API::V2::Schema.cursor_encoder.encode(cursor_parts, nonce: true)
  end
end
