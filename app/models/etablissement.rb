class Etablissement < ApplicationRecord
  belongs_to :dossier
  belongs_to :entreprise, dependent: :destroy

  has_many :exercices, dependent: :destroy

  accepts_nested_attributes_for :exercices
  accepts_nested_attributes_for :entreprise, update_only: true

  validates :dossier_id, uniqueness: true

  def geo_adresse
    [numero_voie, type_voie, nom_voie, complement_adresse, code_postal, localite].join(' ')
  end

  def inline_adresse
    # squeeze needed because of space in excess in the data
    "#{numero_voie} #{type_voie} #{nom_voie}, #{complement_adresse}, #{code_postal} #{localite}".squeeze(' ')
  end

  attr_accessor :entreprise_mandataires_sociaux
end
