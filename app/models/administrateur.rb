# == Schema Information
#
# Table name: administrateurs
#
#  id              :integer          not null, primary key
#  encrypted_token :string
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :bigint           not null
#
class Administrateur < ApplicationRecord
  self.ignored_columns = [:active]

  UNUSED_ADMIN_THRESHOLD = 6.months

  has_and_belongs_to_many :instructeurs
  has_many :administrateurs_procedures
  has_many :procedures, through: :administrateurs_procedures
  has_many :services
  has_many :api_tokens, inverse_of: :administrateur, dependent: :destroy

  belongs_to :user

  default_scope { eager_load(:user) }

  scope :inactive, -> { joins(:user).where(users: { last_sign_in_at: nil }) }
  scope :with_publiees_ou_closes, -> { joins(:procedures).where(procedures: { aasm_state: [:publiee, :close, :depubliee] }) }

  scope :unused, -> do
    joins(:user)
      .where.missing(:services)
      .left_outer_joins(:administrateurs_procedures) # needed to bypass procedure hidden default scope
      .where(administrateurs_procedures: { procedure_id: nil })
      .where("users.last_sign_in_at < ? ", UNUSED_ADMIN_THRESHOLD.ago)
  end

  def self.by_email(email)
    Administrateur.find_by(users: { email: email })
  end

  def email
    user&.email
  end

  def active?
    user&.active?
  end

  def self.find_inactive_by_token(reset_password_token)
    self.inactive.with_reset_password_token(reset_password_token)
  end

  def self.find_inactive_by_id(id)
    self.inactive.find(id)
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
    AdministrateursProcedure.where(administrateur_id: self.id).delete_all
    destroy
  end

  def merge(old_admin)
    return if old_admin.nil?

    procedures_with_new_admin, procedures_without_new_admin = old_admin
      .procedures
      .with_discarded
      .partition { |p| p.administrateurs.exists?(id) }

    procedures_with_new_admin.each do |p|
      p.administrateurs.delete(old_admin)
    end

    procedures_without_new_admin.each do |p|
      p.administrateurs << self
      p.administrateurs.delete(old_admin)
    end

    old_services = old_admin.services
    new_service_by_nom = services.index_by(&:nom)

    old_services.each do |old_service|
      corresponding_service = new_service_by_nom[old_service.nom]
      if corresponding_service.present?
        old_service.procedures.update_all(service_id: corresponding_service.id)
        old_service.destroy
      else
        old_service.update_column(:administrateur_id, id)
      end
    end

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

  def zones
    procedures.joins(:zones).flat_map(&:zones).uniq
  end

  # required to display feature flags field in manager
  def features
  end
end
