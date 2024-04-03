module Mutations
  class WebhookDelete < Mutations::BaseMutation
    description "Delete a webhook"

    argument :webhook_id, ID, "Webhook to delete", required: true, loads: Types::WebhookType

    field :webhook, Types::WebhookType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(webhook:)
      webhook.destroy!

      { webhook: }
    end
  end
end
