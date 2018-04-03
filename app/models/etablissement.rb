class Etablissement < ApplicationRecord
  belongs_to :dossier
  belongs_to :entreprise, dependent: :destroy

  has_one :champ, class_name: 'Champs::SiretChamp'
  has_many :exercices, dependent: :destroy

  accepts_nested_attributes_for :exercices
  accepts_nested_attributes_for :entreprise, update_only: true

  validates :siret, presence: true
  validates :dossier_id, uniqueness: { allow_nil: true }

  validate :validate_signature

  def geo_adresse
    [numero_voie, type_voie, nom_voie, complement_adresse, code_postal, localite].join(' ')
  end

  def inline_adresse
    # squeeze needed because of space in excess in the data
    "#{numero_voie} #{type_voie} #{nom_voie}, #{complement_adresse}, #{code_postal} #{localite}".squeeze(' ')
  end

  def titre
    entreprise_raison_sociale || association_titre
  end

  def verify
    SignatureService.verify(signature, message_for_signature)
  end

  def sign
    SignatureService.sign(message_for_signature)
  end

  attr_accessor :signature

  private

  def validate_signature
    if champ && !verify
      errors.add(:base, 'Numéro SIRET introuvable.')
    end
  end

  def message_for_signature
    JSON.pretty_generate(as_json(include: {
      exercices: { only: [:ca, :date_fin_exercice, :date_fin_exercice_timestamp] }
    }).delete_if { |k,v| v.blank? })
  end
end
