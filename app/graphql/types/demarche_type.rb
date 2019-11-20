module Types
  class DemarcheType < Types::BaseObject
    class DemarcheState < Types::BaseEnum
      Procedure.aasm.states.reject { |state| state.name == :hidden }.each do |state|
        value(state.name.to_s, state.display_name, value: state.name)
      end
    end

    description "Une demarche"

    global_id_field :id
    field :number, ID, "Le numero de la démarche.", null: false, method: :id
    field :title, String, null: false, method: :libelle
    field :description, String, "Déscription de la démarche.", null: false
    field :state, DemarcheState, null: false

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :archived_at, GraphQL::Types::ISO8601DateTime, null: true

    field :groupe_instructeurs, [Types::GroupeInstructeurType], null: false

    field :dossiers, Types::DossierType.connection_type, "Liste de tous les dossiers d'une démarche.", null: false do
      argument :order, Types::Order, default_value: :asc, required: false, description: "L'ordre des dossiers."
      argument :created_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers déposés depuis la date."
      argument :updated_since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers mis à jour depuis la date."
      argument :state, Types::DossierType::DossierState, required: false, description: "Dossiers avec statut."
    end

    field :champ_descriptors, [Types::ChampDescriptorType], null: false, method: :types_de_champ
    field :annotation_descriptors, [Types::ChampDescriptorType], null: false, method: :types_de_champ_private

    def state
      object.aasm.current_state
    end

    def groupe_instructeurs
      Loaders::Association.for(object.class, groupe_instructeurs: { procedure: [:administrateurs] }).load(object)
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

    def self.authorized?(object, context)
      authorized_demarche?(object, context)
    end
  end
end
