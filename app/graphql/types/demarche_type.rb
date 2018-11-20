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

    field :instructeurs, [Types::ProfileType], null: false

    field :dossiers, Types::DossierType.connection_type, "Liste de tous les dossiers d'une démarche.", null: false do
      argument :ids, [ID], required: false, description: "Filtrer les dossiers par ID."
      argument :since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers crées depuis la date."
    end

    def state
      object.aasm.current_state
    end

    def instructeurs
      Loaders::Association.for(Procedure, :instructeurs).load(object)
    end

    def dossiers(ids: nil, since: nil)
      dossiers = object.dossiers.for_api_v2

      if ids.present?
        dossiers = dossiers.where(id: ids)
      end

      if since.present?
        dossiers = dossiers.since(since)
      end

      dossiers
    end
  end
end
