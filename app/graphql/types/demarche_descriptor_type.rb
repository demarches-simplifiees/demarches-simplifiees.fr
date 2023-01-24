module Types
  class DemarcheDescriptorType < Types::BaseObject
    class FindDemarcheInput < Types::BaseInputObject
      one_of
      argument :number, Int, "Numero de la démarche.", required: false
      argument :id, ID, "ID de la démarche.", required: false
    end

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

    field :duree_conservation_dossiers, Int, "Durée de conservation des dossiers en mois.", null: false

    field :demarche_url, String, null: true
    field :site_web_url, String, null: true
    field :dpo_url, String, null: true
    field :notice_url, String, null: true
    field :cadre_juridique_url, String, null: true

    field :opendata, Boolean, null: false
    field :tags, [String], null: false
    field :zones, [String], null: false

    field :revision, Types::RevisionType, null: false
    field :service, Types::ServiceType, null: true

    field :logo, Types::File, null: true, extensions: [{ Extensions::Attachment => { root: :procedure } }]
    field :notice, Types::File, null: true, extensions: [{ Extensions::Attachment => { root: :procedure } }]
    field :deliberation, Types::File, null: true, extensions: [{ Extensions::Attachment => { root: :procedure } }]

    field :dossiers_count, Int, null: false, internal: true

    def service
      Loaders::Record.for(Service).load(procedure.service_id)
    end

    def revision
      if object.is_a?(ProcedureRevision)
        object
      else
        object.active_revision
      end
    end

    def procedure
      if object.is_a?(ProcedureRevision)
        object.procedure
      else
        object
      end
    end

    def dossiers_count
      procedure.dossiers.visible_by_administration.count
    end

    def state
      procedure.aasm.current_state
    end

    delegate :description, :opendata, :tags, to: :procedure

    def demarche_url
      procedure.lien_demarche
    end

    def dpo_url
      procedure.lien_dpo
    end

    def notice_url
      procedure.lien_notice
    end

    def cadre_juridique_url
      procedure.cadre_juridique
    end

    def site_web_url
      procedure.lien_site_web
    end

    def number
      procedure.id
    end

    def title
      procedure.libelle
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

    def duree_conservation_dossiers
      procedure.duree_conservation_dossiers_dans_ds
    end

    def zones
      procedure.zones.map(&:current_label)
    end

    def self.authorized?(object, context)
      procedure = object.is_a?(ProcedureRevision) ? object.procedure : object
      context.authorized_demarche?(procedure, opendata: true)
    end
  end
end
