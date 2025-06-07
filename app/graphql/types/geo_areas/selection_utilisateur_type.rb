# frozen_string_literal: true

module Types::GeoAreas
  class SelectionUtilisateurType < Types::BaseObject
    implements Types::GeoAreaType

    # pf fields
    field :commune, String, null: true
    field :commune_associee, String, null: true
    field :ile, String, null: true
    field :numero, String, null: true
    field :section, String, null: true
  end
end
