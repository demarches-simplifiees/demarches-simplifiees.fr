class Administrateur < ApplicationRecord
  include CredentialsSyncableConcern
  include EmailSanitizableConcern

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :gestionnaires
  has_many :procedures
  has_many :administrateurs_procedures
  has_many :admin_procedures, through: :administrateurs_procedures, source: :procedure

  before_validation -> { sanitize_email(:email) }
  before_save :ensure_api_token

  scope :inactive, -> { where(active: false) }

  def self.find_inactive_by_token(reset_password_token)
    self.inactive.with_reset_password_token(reset_password_token)
  end

  def self.find_inactive_by_id(id)
    self.inactive.find(id)
  end

  def ensure_api_token
    if api_token.nil?
      self.api_token = generate_api_token
    end
  end

  def renew_api_token
    update(api_token: generate_api_token)
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

  def invite!
    if active?
      raise "Impossible d'inviter un utilisateur déjà actif !"
    end

    reset_password_token = set_reset_password_token

    AdministrationMailer.invite_admin(self, reset_password_token).deliver_now!

    reset_password_token
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

  private

  def generate_api_token
    loop do
      token = SecureRandom.hex(20)
      break token if !Administrateur.find_by(api_token: token)
    end
  end
end
