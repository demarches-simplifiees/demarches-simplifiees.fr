class Administrateur < ApplicationRecord
  include CredentialsSyncableConcern
  include EmailSanitizableConcern
  include ActiveRecord::SecureToken

  devise :database_authenticatable, :registerable, :async,
    :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :gestionnaires
  has_many :administrateurs_procedures
  has_many :procedures, through: :administrateurs_procedures
  has_many :services
  has_many :dossiers, -> { state_not_brouillon }, through: :procedures

  before_validation -> { sanitize_email(:email) }

  scope :inactive, -> { where(active: false) }
  scope :with_publiees_ou_archivees, -> { joins(:procedures).where(procedures: { aasm_state: [:publiee, :archivee] }) }

  validate :password_complexity, if: Proc.new { |a| Devise.password_length.include?(a.password.try(:size)) }

  def password_complexity
    if password.present?
      score = Zxcvbn.test(password, [], ZXCVBN_DICTIONNARIES).score
      if score < 4
        errors.add(:password, :not_strength)
      end
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
    elsif reset_password_period_valid?
      'En attente'
    else
      'Expiré'
    end
  end

  def invite!(administration_id)
    if active?
      raise "Impossible d'inviter un utilisateur déjà actif !"
    end

    reset_password_token = set_reset_password_token

    AdministrationMailer.invite_admin(self, reset_password_token, administration_id).deliver_later

    reset_password_token
  end

  def remind_invitation!
    if active?
      raise "Impossible d'envoyer un rappel d'invitation à un utilisateur déjà actif !"
    end

    reset_password_token = set_reset_password_token

    AdministrateurMailer.activate_before_expiration(self, reset_password_token).deliver_later
  end

  def invitation_expired?
    !active && !reset_password_period_valid?
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

  def feature_enabled?(feature)
    Flipflop.feature_set.feature(feature)
    features[feature.to_s]
  end

  def disable_feature(feature)
    Flipflop.feature_set.feature(feature)
    features.delete(feature.to_s)
    save
  end

  def enable_feature(feature)
    Flipflop.feature_set.feature(feature)
    features[feature.to_s] = true
    save
  end

  def owns?(procedure)
    procedure.administrateurs.include?(self)
  end

  def gestionnaire
    Gestionnaire.find_by(email: email)
  end
end
