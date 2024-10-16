# frozen_string_literal: true

class Label < ApplicationRecord
  belongs_to :procedure
  has_many :dossier_labels, dependent: :destroy

  NAME_MAX_LENGTH = 30
  GENERIC_LABELS = [
    { name: 'à relancer', color: 'brown_caramel' },
    { name: 'complet', color: 'green_bourgeon' },
    { name: 'prêt pour validation', color: 'green_archipel' }
  ]

  enum color: {
    green_tilleul_verveine: "green-tilleul-verveine",
    green_bourgeon: "green-bourgeon",
    green_emeraude: "green-emeraude",
    green_menthe: "green-menthe",
    green_archipel: "green-archipel",
    blue_ecume: "blue-ecume",
    blue_cumulus: "blue-cumulus",
    purple_glycine: "purple-glycine",
    pink_macaron: "pink-macaron",
    pink_tuile: "pink-tuile",
    yellow_tournesol: "yellow-tournesol",
    yellow_moutarde: "yellow-moutarde",
    orange_terre_battue: "orange-terre-battue",
    brown_cafe_creme: "brown-cafe-creme",
    brown_caramel: "brown-caramel",
    brown_opera: "brown-opera",
    beige_gris_galet: "beige-gris-galet"
  }

  validates :name, :color, presence: true
  validates :name, length: { maximum: NAME_MAX_LENGTH }
end
