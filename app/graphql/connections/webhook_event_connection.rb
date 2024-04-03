module Connections
  class WebhookEventConnection < CursorConnection
    private

    def order_column
      :enqueued_at
    end

    def order_table
      :webhook_events
    end
  end
end
