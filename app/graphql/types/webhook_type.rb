module Types
  class WebhookType < Types::BaseObject
    class WebhookEventTypeType < Types::BaseEnum
      Webhook.event_types.each do |event_type, event_type_value|
        value(event_type, event_type_value, value: event_type_value)
      end
    end

    global_id_field :id
    field :label, String, "Le nom du webhook.", null: false
    field :event_type, [WebhookEventTypeType], "Le type d'événement déclenchant le webhook.", null: false
    field :url, Types::URL, "Webhook URL", null: false
    field :enabled, Boolean, "Le webhook est-il actif", null: false
    field :secret, String, "Le secret du webhook.", null: false
    field :last_success_at, GraphQL::Types::ISO8601DateTime, "Dernière réussite", null: true
    field :last_error_at, GraphQL::Types::ISO8601DateTime, "Dernière erreur", null: true
    field :last_error_message, String, "Message d'erreur", null: true

    def self.authorized?(object, context)
      context.authorized_demarche?(object.procedure)
    end
  end
end
