module Types
  class DemarcheDescriptorType < Types::BaseObject
    field_class BaseField
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
    field :service, Types::ServiceType, null: true

    field :cadre_juridique, String, null: true
    field :deliberation, String, null: true

    field :dossiers_count, Int, null: false, require_admin: true

    def service
      Loaders::Record.for(Service).load(procedure.service_id)
    end

    def revision
      object.is_a?(ProcedureRevision) ? object : object.active_revision
    end

    def dossiers_count
      object.dossiers.count
    end

    def deliberation
      Rails.application.routes.url_helpers.url_for(procedure.deliberation) if procedure.deliberation.attached?
    end

    def state
      procedure.aasm.current_state
    end

    def cadre_juridique
      procedure.cadre_juridique
    end

    def number
      procedure.id
    end

    def title
      procedure.libelle
    end

    def description
      procedure.description
    end

    def declarative
      procedure.declarative_with_state
    end

    def date_creation
      procedure.created_at
    end

    def date_publication
      procedure.published_at
    end

    def date_derniere_modification
      procedure.updated_at
    end

    def date_depublication
      procedure.unpublished_at
    end

    def date_fermeture
      procedure.closed_at
    end

    def self.authorized?(object, context)
      if object.is_a?(ProcedureRevision)
        context.authorized_demarche?(object.procedure)
      else
        context.authorized_demarche?(object)
      end
    end

    private

    def procedure
      revision.procedure
    end
  end
end
