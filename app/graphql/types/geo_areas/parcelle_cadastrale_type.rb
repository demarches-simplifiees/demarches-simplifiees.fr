# frozen_string_literal: true

module Types::GeoAreas
  class ParcelleCadastraleType < Types::BaseObject
    implements Types::GeoAreaType

    field :numero, String, null: false
    field :section, String, null: false
    field :surface, String, null: false
    field :prefixe, String, null: false
    field :commune, String, null: false
    # pf fields
    field :commune_associee, String, null: false
    field :ile, String, null: false

    field :code_dep, String, null: false, deprecation_reason: 'Utilisez le champ `commune` à la place.'
    field :nom_com, String, null: false, deprecation_reason: 'Utilisez le champ `commune` à la place.'
    field :code_com, String, null: false, deprecation_reason: 'Utilisez le champ `commune` à la place.'
    field :code_arr, String, null: false, deprecation_reason: 'Utilisez le champ `prefixe` à la place.'
    field :feuille, Int, null: false, deprecation_reason: 'L’information n’est plus disponible.'
    field :surface_intersection, Float, null: false, deprecation_reason: 'L’information n’est plus disponible.'
    field :surface_parcelle, Float, null: false, deprecation_reason: 'Utilisez le champ `surface` à la place.'
  end
end
