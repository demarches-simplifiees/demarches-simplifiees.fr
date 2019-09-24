module Types::GeoAreas
  class ParcelleCadastraleType < Types::BaseObject
    implements Types::GeoAreaType

    field :surface_intersection, Float, null: false
    field :surface_parcelle, Float, null: false
    field :numero, String, null: false
    field :feuille, Int, null: false
    field :section, String, null: false
    field :code_dep, String, null: false
    field :nom_com, String, null: false
    field :code_com, String, null: false
    field :code_arr, String, null: false
  end
end
