module Types::GeoAreas
  class QuartierPrioritaireType < Types::BaseObject
    implements Types::GeoAreaType

    field :code, String, null: false
    field :nom, String, null: false
    field :commune, String, null: false
  end
end
