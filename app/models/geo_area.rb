class GeoArea < ApplicationRecord
  belongs_to :champ

  store :properties, accessors: [
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
  ]

  enum source: {
    quartier_prioritaire: 'quartier_prioritaire',
    cadastre: 'cadastre'
  }

  scope :quartiers_prioritaires, -> { where(source: sources.fetch(:quartier_prioritaire)) }
  scope :cadastres, -> { where(source: sources.fetch(:cadastre)) }
end
