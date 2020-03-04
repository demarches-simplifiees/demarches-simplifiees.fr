module Types
  class QueryType < Types::BaseObject
    field :demarche, DemarcheType, null: false, description: "Informations concernant une démarche." do
      argument :number, Int, "Numéro de la démarche.", required: true
    end

    field :demarches, [DemarcheDescriptorType], null: false, description: "Liste des démarches." do
      argument :state, Types::DemarcheType::DemarcheState, "État de la démarche.", required: false
    end

    field :dossier, DossierType, null: false, description: "Informations sur un dossier d'une démarche." do
      argument :number, Int, "Numéro du dossier.", required: true
    end

    def demarche(number:)
      Procedure.for_api_v2.find(number)
    rescue => e
      raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
    end

    def dossier(number:)
      Dossier.for_api_v2.find(number)
    rescue => e
      raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
    end

    def demarches(state: nil)
      if context[:administrateur_id]
        procedures = Administrateur.find(context[:administrateur_id]).procedures.for_api_v2

        if state.present?
          procedures.where(aasm_state: state)
        else
          procedures.publiees
        end
      else
        []
      end
    end

    def self.accessible?(context)
      context[:token] || context[:administrateur_id]
    end
  end
end
