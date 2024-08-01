# frozen_string_literal: true

class ContactInformation < ApplicationRecord
  include EmailSanitizableConcern

  belongs_to :groupe_instructeur

  validates :nom, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :nom, uniqueness: { scope: :groupe_instructeur, message: 'existe déjà' }
  validates :email, strict_email: true, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :telephone, phone: { possible: true, allow_blank: false }
  validates :horaires, presence: { message: 'doivent être renseignés' }, allow_nil: false
  validates :adresse, presence: { message: 'doit être renseignée' }, allow_nil: false
  validates :groupe_instructeur, presence: { message: 'doit être renseigné' }, allow_nil: false
  before_validation -> { sanitize_email(:email) }

  def pretty_nom
    nom
  end

  def telephone_url
    if telephone.present?
      "tel:#{telephone.gsub(/[[:blank:]]/, '')}"
    end
  end

  def organisme
  end
end
