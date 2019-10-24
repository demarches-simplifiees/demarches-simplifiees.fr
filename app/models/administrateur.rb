class Administrateur < ApplicationRecord
  self.ignored_columns = ['features', 'encrypted_password', 'reset_password_token', 'reset_password_sent_at', 'remember_created_at', 'sign_in_count', 'current_sign_in_at', 'last_sign_in_at', 'current_sign_in_ip', 'last_sign_in_ip', 'failed_attempts', 'unlock_token', 'locked_at']
  include EmailSanitizableConcern
  include ActiveRecord::SecureToken

  has_and_belongs_to_many :instructeurs
  has_many :administrateurs_procedures
  has_many :procedures, through: :administrateurs_procedures
  has_many :services
  has_many :dossiers, -> { state_not_brouillon }, through: :procedures

  has_one :user, dependent: :nullify

  before_validation -> { sanitize_email(:email) }

  scope :inactive, -> { joins(:user).where(users: { last_sign_in_at: nil }) }
  scope :with_publiees_ou_archivees, -> { joins(:procedures).where(procedures: { aasm_state: [:publiee, :archivee] }) }

  # validate :password_complexity, if: Proc.new { |a| Devise.password_length.include?(a.password.try(:size)) }

  def password_complexity
    if password.present? && ZxcvbnService.new(password).score < PASSWORD_COMPLEXITY_FOR_ADMIN
      errors.add(:password, :not_strong)
    end
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
    if active?
      'Actif'
    elsif user.reset_password_period_valid?
      'En attente'
    else
      'Expiré'
    end
  end

  def invitation_expired?
    !active? && !user.reset_password_period_valid?
  end

  def self.reset_password(reset_password_token, password)
    administrateur = self.reset_password_by_token({
      password: password,
      password_confirmation: password,
      reset_password_token: reset_password_token
    })

    if administrateur && administrateur.errors.empty?
      administrateur.update_column(:active, true)
    end

    administrateur
  end

  def owns?(procedure)
    procedure.administrateurs.include?(self)
  end

  def instructeur
    Instructeur.find_by(email: email)
  end

  def can_be_deleted?
    dossiers.state_instruction_commencee.none? && procedures.none?
  end

  def active?
    user.last_sign_in_at.present?
  end
end
