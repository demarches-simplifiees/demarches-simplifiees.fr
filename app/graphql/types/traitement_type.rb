module Types
  class TraitementType < Types::BaseObject
    global_id_field :id
    field :processed_at, GraphQL::Types::ISO8601DateTime, 'La date de la décision', null: false
    field :state, Types::DossierType::DossierState, "La décision sur le dossier.", null: false
    field :motivation, String, 'La motivation de la décision.', null: false
    field :instructeur_email, String, "L'instructeur ayant pris la décision.", null: false
  end
end
