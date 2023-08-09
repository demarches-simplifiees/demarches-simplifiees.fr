module Types
  class PersonneMoraleIncompleteType < Types::BaseObject
    implements Types::DemandeurType

    field :siret, String, null: false
  end
end
