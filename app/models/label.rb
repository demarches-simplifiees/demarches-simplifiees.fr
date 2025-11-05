# frozen_string_literal: true

class Label < ApplicationRecord
  belongs_to :procedure
  has_many :dossier_labels, dependent: :destroy

  NAME_MAX_LENGTH = 30
  GENERIC_LABELS = [
    { name: 'À examiner', color: 'purple_glycine' },
    { name: 'À relancer', color: 'green_tilleul_verveine' },
    { name: 'Complet', color: 'green_emeraude' },
    { name: 'À signer', color: 'blue_ecume' },
    { name: 'Urgent', color: 'pink_macaron' },
  ]

  enum :color, {
    green_tilleul_verveine: "green-tilleul-verveine",
    green_bourgeon: "green-bourgeon",
    green_emeraude: "green-emeraude",
    green_menthe: "green-menthe",
    blue_ecume: "blue-ecume",
    purple_glycine: "purple-glycine",
    pink_macaron: "pink-macaron",
    yellow_tournesol: "yellow-tournesol",
    brown_cafe_creme: "brown-cafe-creme",
    beige_gris_galet: "beige-gris-galet",
  }

  validates :name, :color, presence: true
  validates :name, length: { maximum: NAME_MAX_LENGTH }

  def self.class_name(color)
    Label.colors.fetch(color.underscore)
  end
end
