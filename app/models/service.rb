# frozen_string_literal: true

class Service < ApplicationRecord
  include PrefillableFromServicePublicConcern

  has_many :procedures
  belongs_to :administrateur, optional: false

  scope :ordered, -> { order(nom: :asc) }

  SIRET_TEST = '35600082800018'

  enum type_organisme: {
    administration_centrale: 'administration_centrale',
    association: 'association',
    collectivite_territoriale: 'collectivite_territoriale',
    etablissement_enseignement: 'etablissement_enseignement',
    operateur_d_etat: "operateur_d_etat",
    service_deconcentre_de_l_etat: 'service_deconcentre_de_l_etat',
    autre: 'autre'
  }

  before_validation :strip_email
  validate :validate_email_or_url

  validates :nom, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :nom, uniqueness: { scope: :administrateur, message: 'existe déjà' }
  validates :organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :siret, siret_format: true
  validates :siret, comparison: { other_than: SIRET_TEST, message: "n'est pas valide" }, on: :update
  validates :type_organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :email, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :telephone, phone: { possible: true, allow_blank: true }
  validates :horaires, presence: { message: 'doivent être renseignés' }, allow_nil: false
  validates :adresse, presence: { message: 'doit être renseignée' }, allow_nil: false
  validates :administrateur, presence: { message: 'doit être renseigné' }, allow_nil: false

  def pretty_nom
    "#{nom}, #{organisme}"
  end

  def clone_and_assign_to_administrateur(administrateur)
    service_cloned = self.dup
    service_cloned.administrateur = administrateur
    service_cloned
  end

  def telephone_url
    if telephone.present?
      "tel:#{telephone.gsub(/[[:blank:]]/, '')}"
    end
  end

  def etablissement_adresse
    etablissement_infos.fetch("adresse", nil)
  end

  def etablissement_latlng
    [etablissement_lat, etablissement_lng]
  end

  def enqueue_api_entreprise
    APIEntreprise::ServiceJob.perform_later(self.id)
  end

  private

  def strip_email
    self.email = email.strip if email.present?
  end

  def validate_email_or_url
    return if email.blank?

    # Vérifie d'abord si c'est un email valide avec StrictEmailValidator
    return if StrictEmailValidator::REGEXP.match?(email)

    # Si ce n'est pas un email valide, vérifie si c'est une URL valide
    url_validator = URLValidator.new(
      attributes: { allow_blank: true },
      no_local: true,
    )
    
    url_validator.validate_each(self, :email, email)
  end
end
