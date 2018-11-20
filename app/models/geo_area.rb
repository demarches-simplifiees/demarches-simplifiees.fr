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
    :commune,
    :culture,
    :code_culture,
    :surface,
    :bio
  ]

  enum source: {
    quartier_prioritaire: 'quartier_prioritaire',
    cadastre: 'cadastre',
    parcelle_agricole: 'parcelle_agricole',
    selection_utilisateur: 'selection_utilisateur'
  }

  scope :quartiers_prioritaires, -> { where(source: sources.fetch(:quartier_prioritaire)) }
  scope :cadastres, -> { where(source: sources.fetch(:cadastre)) }
  scope :parcelles_agricoles, -> { where(source: sources.fetch(:parcelle_agricole)) }
end
