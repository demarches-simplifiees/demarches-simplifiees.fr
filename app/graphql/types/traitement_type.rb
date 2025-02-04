# frozen_string_literal: true

module Types
  class TraitementType < Types::BaseObject
    global_id_field :id
    field :state, Types::DossierType::DossierState, null: false
    field :date_traitement, GraphQL::Types::ISO8601DateTime, null: false, method: :processed_at
    field :email_agent_traitant, String, null: true, method: :instructeur_email
    field :motivation, String, null: true
    field :revision, Types::RevisionType, null: true

    def revision
      Loaders::Association.for(object.class, :revision).load(object)
    end
  end
end
