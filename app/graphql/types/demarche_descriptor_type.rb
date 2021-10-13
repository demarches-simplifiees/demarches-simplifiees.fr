module Types
  class DemarcheDescriptorType < Types::BaseObject
    description "Une démarche (métadonnées)
Ceci est une version abrégée du type `Demarche`, qui n’expose que les métadonnées.
Cela évite l’accès récursif aux dossiers."

    global_id_field :id
    field :number, Int, "Numero de la démarche.", null: false, method: :id
    field :title, String, "Titre de la démarche.", null: false, method: :libelle
    field :description, String, "Description de la démarche.", null: false
    field :state, Types::DemarcheType::DemarcheState, "État de la démarche.", null: false
    field :declarative, Types::DemarcheType::DossierDeclarativeState, "Pour une démarche déclarative, état cible des dossiers à valider automatiquement", null: true, method: :declarative_with_state

    field :date_creation, GraphQL::Types::ISO8601DateTime, "Date de la création.", null: false, method: :created_at
    field :date_publication, GraphQL::Types::ISO8601DateTime, "Date de la publication.", null: true, method: :published_at
    field :date_derniere_modification, GraphQL::Types::ISO8601DateTime, "Date de la dernière modification.", null: false, method: :updated_at
    field :date_depublication, GraphQL::Types::ISO8601DateTime, "Date de la dépublication.", null: true, method: :unpublished_at
    field :date_fermeture, GraphQL::Types::ISO8601DateTime, "Date de la fermeture.", null: true, method: :closed_at

    def state
      object.aasm.current_state
    end
  end
end
