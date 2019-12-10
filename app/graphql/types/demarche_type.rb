module Types
  class DemarcheType < Types::BaseObject
    class DemarcheState < Types::BaseEnum
      Procedure.aasm.states.reject { |state| state.name == :hidden }.each do |state|
        value(state.name.to_s, state.display_name, value: state.name)
      end
    end

    class DossierDeclarativeState < Types::BaseEnum
      Procedure.declarative_with_states.each do |symbol_name, string_name|
        value(string_name,
          I18n.t("declarative_with_state/#{string_name}", scope: [:activerecord, :attributes, :procedure]),
          value: symbol_name)
      end
    end

    description "Une demarche"

    global_id_field :id
    field :number, Int, "Le numero de la démarche.", null: false, method: :id
    field :title, String, "Le titre de la démarche.", null: false, method: :libelle
    field :description, String, "Description de la démarche.", null: false
    field :state, DemarcheState, "L'état de la démarche.", null: false
    field :declarative, DossierDeclarativeState, "L'état de dossier pour une démarche déclarative", null: true, method: :declarative_with_state

    field :date_creation, GraphQL::Types::ISO8601DateTime, "Date de la création.", null: false, method: :created_at
    field :date_publication, GraphQL::Types::ISO8601DateTime, "Date de la publication.", null: false, method: :published_at
    field :date_derniere_modification, GraphQL::Types::ISO8601DateTime, "Date de la dernière modification.", null: false, method: :updated_at
    field :date_depublication, GraphQL::Types::ISO8601DateTime, "Date de la dépublication.", null: true, method: :unpublished_at
    field :date_fermeture, GraphQL::Types::ISO8601DateTime, "Date de la fermeture.", null: true, method: :closed_at

    field :groupe_instructeurs, [Types::GroupeInstructeurType], null: false
    field :service, Types::ServiceType, null: false

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

    def service
      Loaders::Record.for(Service).load(object.service_id)
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
