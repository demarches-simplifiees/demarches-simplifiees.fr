class Etablissement < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :entreprise

  has_many :exercices, dependent: :destroy

  accepts_nested_attributes_for :exercices
  accepts_nested_attributes_for :entreprise

  validates_uniqueness_of :dossier_id

  def geo_adresse
    [numero_voie, type_voie, nom_voie, complement_adresse, code_postal, localite].join(' ')
  end

  def inline_adresse
    # squeeze needed because of space in excess in the data
    "#{numero_voie} #{type_voie} #{nom_voie}, #{complement_adresse}, #{code_postal} #{localite}".squeeze(' ')
  end

  attr_accessor :entreprise_mandataires_sociaux

  def mandataire_social?(france_connect_information)
    if france_connect_information.present?
      entreprise_mandataires_sociaux&.find do |mandataire|
        france_connect_information.mandataire_social?(mandataire)
      end
    end
  end
end
