module Types
  class DemarcheDescriptorType < Types::BaseObject
    description "Une démarche (métadonnées)
Ceci est une version abrégée du type `Demarche`, qui n’expose que les métadonnées.
Cela évite l’accès récursif aux dossiers."

    global_id_field :id
    field :number, Int, "Numero de la démarche.", null: false
    field :title, String, "Titre de la démarche.", null: false
    field :description, String, "Description de la démarche.", null: false
    field :state, Types::DemarcheType::DemarcheState, "État de la démarche.", null: false
    field :declarative, Types::DemarcheType::DossierDeclarativeState, "Pour une démarche déclarative, état cible des dossiers à valider automatiquement", null: true

    field :date_creation, GraphQL::Types::ISO8601DateTime, "Date de la création.", null: false
    field :date_publication, GraphQL::Types::ISO8601DateTime, "Date de la publication.", null: true
    field :date_derniere_modification, GraphQL::Types::ISO8601DateTime, "Date de la dernière modification.", null: false
    field :date_depublication, GraphQL::Types::ISO8601DateTime, "Date de la dépublication.", null: true
    field :date_fermeture, GraphQL::Types::ISO8601DateTime, "Date de la fermeture.", null: true

    field :revision, Types::RevisionType, null: false
    field :service, Types::ServiceType, null: false

    def service
      Loaders::Record.for(Service).load(object.procedure.service_id)
    end

    def revision
      object
    end

    def state
      object.procedure.aasm.current_state
    end

    def number
      object.procedure.id
    end

    def title
      object.procedure.libelle
    end

    def description
      object.procedure.description
    end

    def declarative
      object.procedure.declarative_with_state
    end

    def date_creation
      object.procedure.created_at
    end

    def date_publication
      object.procedure.published_at
    end

    def date_derniere_modification
      object.procedure.updated_at
    end

    def date_depublication
      object.procedure.unpublished_at
    end

    def date_fermeture
      object.procedure.closed_at
    end

    def self.authorized?(object, context)
      context.authorized_demarche?(object.procedure)
    end
  end
end
