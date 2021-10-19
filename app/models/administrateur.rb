# == Schema Information
#
# Table name: administrateurs
#
#  id              :integer          not null, primary key
#  active          :boolean          default(FALSE)
#  encrypted_token :string
#  created_at      :datetime
#  updated_at      :datetime
#
class Administrateur < ApplicationRecord
  include ActiveRecord::SecureToken

  has_and_belongs_to_many :instructeurs
  has_many :administrateurs_procedures
  has_many :procedures, through: :administrateurs_procedures
  has_many :services

  has_one :user, dependent: :nullify

  default_scope { eager_load(:user) }

  scope :inactive, -> { joins(:user).where(users: { last_sign_in_at: nil }) }
  scope :with_publiees_ou_closes, -> { joins(:procedures).where(procedures: { aasm_state: [:publiee, :close, :depubliee] }) }

  def self.by_email(email)
    Administrateur.find_by(users: { email: email })
  end

  def email
    user&.email
  end

  def self.find_inactive_by_token(reset_password_token)
    self.inactive.with_reset_password_token(reset_password_token)
  end

  def self.find_inactive_by_id(id)
    self.inactive.find(id)
  end

  def renew_api_token
    api_token = Administrateur.generate_unique_secure_token
    encrypted_token = BCrypt::Password.create(api_token)
    update(encrypted_token: encrypted_token)
    api_token
  end

  def valid_api_token?(api_token)
    BCrypt::Password.new(encrypted_token) == api_token
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def registration_state
    if user.active?
      'Actif'
    elsif user.reset_password_period_valid?
      'En attente'
    else
      'Expiré'
    end
  end

  def invitation_expired?
    !user.active? && !user.reset_password_period_valid?
  end

  def owns?(procedure)
    procedure.administrateurs.include?(self)
  end

  def instructeur
    user.instructeur
  end

  def can_be_deleted?
    procedures.all? { |p| p.administrateurs.count > 1 }
  end

  def delete_and_transfer_services
    if !can_be_deleted?
      fail "Impossible de supprimer cet administrateur car il a des démarches où il est le seul administrateur"
    end

    procedures.with_discarded.each do |procedure|
      next_administrateur = procedure.administrateurs.where.not(id: self.id).first
      procedure.service.update(administrateur: next_administrateur)
    end

    services.each do |service|
      # We can't destroy a service if it has procedures, even if those procedures are archived
      service.destroy unless service.procedures.with_discarded.any?
    end

    destroy
  end

  def merge(old_admin)
    return if old_admin.nil?

    procedures_with_new_admin, procedures_without_new_admin = old_admin.procedures
      .partition { |p| p.administrateurs.exists?(id) }

    procedures_with_new_admin.each do |p|
      p.administrateurs.delete(old_admin)
    end

    procedures_without_new_admin.each do |p|
      p.administrateurs << self
      p.administrateurs.delete(old_admin)
    end

    old_admin.services.update_all(administrateur_id: id)

    instructeurs_with_new_admin, instructeurs_without_new_admin = old_admin.instructeurs
      .partition { |i| i.administrateurs.exists?(id) }

    instructeurs_with_new_admin.each do |i|
      i.administrateurs.delete(old_admin)
    end

    instructeurs_without_new_admin.each do |i|
      i.administrateurs << self
      i.administrateurs.delete(old_admin)
    end
  end

  # required to display feature flags field in manager
  def features
  end
end
