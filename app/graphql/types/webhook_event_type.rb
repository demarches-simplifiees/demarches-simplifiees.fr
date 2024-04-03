module Types
  class WebhookEventType < Types::BaseObject
    global_id_field :id
    field :enqueued_at, GraphQL::Types::ISO8601DateTime, "Date de l'enregistrement.", null: false
    field :event_type, [Types::WebhookType::WebhookEventTypeType], "Le type d'événement déclenchant le webhook.", null: false
    field :resource_type, String, null: false
    field :resource_id, String, null: false
    field :resource_version, String, null: false
  end
end
