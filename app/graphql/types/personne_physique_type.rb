module Types
  class PersonnePhysiqueType < Types::BaseObject
    implements Types::DemandeurType

    field :nom, String, null: false
    field :prenom, String, null: false
    field :civilite, Types::Civilite, null: true, method: :gender
    field :date_de_naissance, GraphQL::Types::ISO8601Date, null: true, method: :birthdate
  end
end
