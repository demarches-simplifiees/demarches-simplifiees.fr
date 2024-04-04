module Types
  class QueryType < Types::BaseObject
    field :demarche, DemarcheType, null: false, description: "Informations concernant une démarche." do
      argument :number, Int, "Numéro de la démarche.", required: true
    end

    field :dossier, DossierType, null: false, description: "Informations sur un dossier d’une démarche." do
      argument :number, Int, "Numéro du dossier.", required: true
    end

    field :groupe_instructeur, GroupeInstructeurWithDossiersType, null: false, description: "Informations sur un groupe instructeur." do
      argument :number, Int, "Numéro du groupe instructeur.", required: true
    end

    field :demarche_descriptor, DemarcheDescriptorType, null: true do
      argument :demarche, DemarcheDescriptorType::FindDemarcheInput, "La démarche.", required: true
    end

    field :demarches_publiques, DemarcheDescriptorType.connection_type, null: false, internal: true

    field :webhook, Types::WebhookEventType.connection_type, "Les événements d’un webhook", null: false do
      argument :id, ID, "Webhook ID.", required: true
    end

    def demarches_publiques
      Procedure.publiques.includes(draft_revision: :procedure, published_revision: :procedure)
    end

    def demarche_descriptor(demarche:)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      Procedure
        .includes(draft_revision: :procedure, published_revision: :procedure)
        .find(demarche_number)
    end

    def demarche(number:)
      Procedure.for_api_v2.find(number)
    end

    def dossier(number:)
      dossier = if context.internal_use?
        Dossier.state_not_brouillon.for_api_v2.find(number)
      else
        Dossier.visible_by_administration.for_api_v2.find(number)
      end
      DossierPreloader.load_one(dossier)
    end

    def groupe_instructeur(number:)
      GroupeInstructeur.for_api_v2.find(number)
    end

    def webhook(id:)
      webhook_id = ApplicationRecord.id_from_typed_id(id)
      webhook = Webhook.find(webhook_id)

      if context.authorized_demarche?(webhook.procedure)
        WebhookEventConnection.new(webhook.events)
      else
        raise GraphQL::ExecutionError, "Vous n’avez pas les droits d’accès à ce webhook"
      end
    end

    def self.accessible?(context)
      context[:token] || context[:administrateur_id]
    end
  end
end
