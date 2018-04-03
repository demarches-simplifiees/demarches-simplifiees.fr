class Etablissement < ApplicationRecord
  belongs_to :dossier
  belongs_to :entreprise, dependent: :destroy

  has_one :champ, class_name: 'Champs::SiretChamp'
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
  def verify
    SignatureService.verify(signature, message_for_signature)
  end

  def sign
    SignatureService.sign(message_for_signature)
  end

  attr_accessor :signature

  def message_for_signature
    JSON.pretty_generate(as_json(include: {
      exercices: { only: [:ca, :date_fin_exercice, :date_fin_exercice_timestamp] }
    }).delete_if { |k,v| v.blank? })
  end
end
