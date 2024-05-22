module Mutations
  class WebhookCreate < Mutations::BaseMutation
    description "Create a webhook"

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "Demarche ID ou numéro.", required: true
    argument :url, Types::URL, "L'URL du webhook", required: true
    argument :label, String, "Le libellé du webhook", required: true
    argument :event_type, [Types::WebhookType::WebhookEventTypeType], "Le type d’événement déclenchant le webhook", required: true
    argument :enabled, Boolean, "Le webhook est-il actif", required: false

    field :webhook, Types::WebhookType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(demarche:, url:, label:, event_type:, enabled: true)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      procedure = Procedure.find_by(id: demarche_number)

      if context.authorized_demarche?(procedure)
        webhook = procedure.webhooks.build(url:, label:, event_type:, enabled:)

        if webhook.save
          { webhook: }
        else
          { errors: webhook.errors.full_messages }
        end
      else
        { errors: ["Vous n’avez pas les droits d’accès à cette démarche"] }
      end
    end
  end
end
