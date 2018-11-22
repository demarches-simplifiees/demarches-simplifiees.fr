module Types
  class DemarcheType < Types::BaseObject
    include Rails.application.routes.url_helpers

    description "Une demarche"

    field :id, ID, "L'ID de la démarche.", null: false
    field :title, String, null: false, method: :libelle
    field :description, String, "Déscription de la démarche.", null: false
    field :state, Types::DemarcheStateType, null: false

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :archived_at, GraphQL::Types::ISO8601DateTime, null: true

    field :public_url, Types::URL, "Lien public de la démarche.", null: true
    field :website_url, Types::URL, "Lien vers le site internet de la démarche.", null: true
    field :notice_url, Types::URL, "Lien vers la notice explicative de la démarche.", null: true
    field :deliberation_url, Types::URL, "Lien vers le texte qui justifie le droit de collecter les données demandées dans votre démarche auprès des usagers.", null: true

    field :instructeurs, [Types::ProfileType], null: false

    field :dossiers, Types::DossierType.connection_type, "Liste de tous les dossiers d'une démarche.", null: false do
      argument :ids, [ID], required: false, description: "Filtrer les dossiers par ID."
      argument :since, GraphQL::Types::ISO8601DateTime, required: false, description: "Dossiers crées depuis la date."
    end

    def state
      object.aasm_state.to_s.upcase
    end

    def public_url
      if object.path.present?
        if object.brouillon_avec_lien?
          commencer_test_url(procedure_path: object.path)
        else
          commencer_url(procedure_path: object.path)
        end
      end
    end

    def notice_url
      if object.notice.attached?
        url_for(object.notice)
      end
    end

    def deliberation_url
      if object.deliberation.attached?
        url_for(object.deliberation)
      elsif object.cadre_juridique.present?
        object.cadre_juridique
      end
    end

    def instructeurs
      Loaders::DemarcheInstructeurs.load(object.id)
    end

    def dossiers(ids: nil, since: nil)
      dossiers = object.dossiers.with_graph

      if ids.present?
        dossiers.where!(ids: ids)
      end

      if since.present?
        dossiers.where!("created_at >= ?", since)
      end

      dossiers
    end

    def self.authorized?(object, context)
      authorized_demarche?(object, context)
    end
  end
end
