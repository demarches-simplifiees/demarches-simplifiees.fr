# frozen_string_literal: true

module Types
  class TraitementType < Types::BaseObject
    global_id_field :id
    field :state, Types::DossierType::DossierState, "La décision sur le dossier.", null: false
    field :date_traitement, GraphQL::Types::ISO8601DateTime, 'La date de la décision', null: false, method: :processed_at
    field :email_agent_traitant, String, "L'instructeur ayant pris la décision.", null: true, method: :instructeur_email
    field :motivation, String, 'La motivation de la décision.', null: true

    # compatibility with pf API
    field :processed_at, GraphQL::Types::ISO8601DateTime, 'La date de la décision', null: false
    field :instructeur_email, String, "L'instructeur ayant pris la décision.", null: true
  end
end
