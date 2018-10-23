class GeoAreaSerializer < ActiveModel::Serializer
  attributes :geometry,
    :source,
    :surface_intersection,
    :surface_parcelle,
    :numero,
    :feuille,
    :section,
    :code_dep,
    :nom_com,
    :code_com,
    :code_arr,
    :code,
    :nom,
    :commune
end
