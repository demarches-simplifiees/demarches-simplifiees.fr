module Types::GeoAreas
  class SelectionUtilisateurType < Types::BaseObject
    implements Types::GeoAreaType

    field :description, String, null: false
  end
end
