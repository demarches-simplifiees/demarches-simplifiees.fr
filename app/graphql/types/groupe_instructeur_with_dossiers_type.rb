module Types
  class GroupeInstructeurWithDossiersType < GroupeInstructeurType
    description "Un groupe instructeur avec ces dossiers"

    field :dossiers, Types::DossierType.connection_type, "Liste de tous les dossiers d'une démarche.", null: false do
      argument :order, Types::Order, default_value: :asc, required: false, description: "L'ordre des dossiers."
      argument :created_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers déposés depuis la date."
      argument :updated_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers mis à jour depuis la date."
      argument :state, Types::DossierType::DossierState, required: false, description: "Dossiers avec statut."
    end

    def dossiers(updated_since: nil, created_since: nil, state: nil, order:)
      dossiers = object.dossiers.state_not_brouillon.for_api_v2

      if state.present?
        dossiers = dossiers.where(state: state)
      end

      if updated_since.present?
        dossiers = dossiers.updated_since(updated_since).order_by_updated_at(order)
      else
        if created_since.present?
          dossiers = dossiers.created_since(created_since)
        end

        dossiers = dossiers.order_by_created_at(order)
      end

      dossiers
    end
  end
end
