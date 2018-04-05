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

  def entreprise_raison_sociale_or_name
    entreprise_raison_sociale.presence || "#{entreprise_nom} #{entreprise_prenom}"
  end

  def entreprise_effectif
    {
      'NN' => "Unités non employeuses (pas de salarié au cours de l'année de référence et pas d'effectif au 31/12).",
      '00' => "0 salarié (n'ayant pas d'effectif au 31/12 mais ayant employé des salariés au cours de l'année de référence)",
      '01' => '1 ou 2 salariés',
      '02' => '3 à 5 salariés',
      '03' => '6 à 9 salariés',
      '11' => '10 à 19 salariés',
      '12' => '20 à 49 salariés',
      '21' => '50 à 99 salariés',
      '22' => '100 à 199 salariés',
      '31' => '200 à 249 salariés',
      '32' => '250 à 499 salariés',
      '41' => '500 à 999 salariés',
      '42' => '1 000 à 1 999 salariés',
      '51' => '2 000 à 4 999 salariés',
      '52' => '5 000 à 9 999 salariés',
      '53' => '10 000 salariés et plus'
    }[entreprise_code_effectif_entreprise]
  end

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
