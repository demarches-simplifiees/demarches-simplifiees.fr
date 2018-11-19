module Types
  class QueryType < Types::BaseObject
    field :demarche, DemarcheType, null: false, description: "Informations concernant une démarche." do
      argument :id, ID, "Numéro de la démarche.", required: true
    end

    field :dossier, DossierType, null: false, description: "Informations sur un dossier d'une démarche." do
      argument :id, ID, "Numéro du dossier.", required: true
    end

    def demarche(id:)
      Procedure.for_api_v2.find(id)
    rescue => e
      raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
    end

    def dossier(id:)
      Dossier.for_api_v2.find(id)
    rescue => e
      raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
    end

    def self.accessible?(context)
      context[:token] || context[:administrateur_id]
    end
  end
end
