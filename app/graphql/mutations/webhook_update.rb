module Mutations
  class WebhookUpdate < Mutations::BaseMutation
    description "Update a webhook"

    argument :webhook_id, ID, "Webhook to update", required: true, loads: Types::WebhookType

    argument :url, Types::URL, "L'URL du webhook", required: false
    argument :label, String, "Le libellé du webhook", required: false
    argument :event_type, [Types::WebhookType::WebhookEventTypeType], "Le type d’événement déclenchant le webhook", required: false
    argument :enabled, Boolean, "Le webhook est-il actif", required: false

    field :webhook, Types::WebhookType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(webhook:, url: nil, label: nil, event_type: nil, enabled: nil)
      webhook.attributes = { url:, label:, event_type:, enabled: }.compact

      if webhook.save
        { webhook: }
      else
        { errors: webhook.errors.full_messages }
      end
    end
  end
end
