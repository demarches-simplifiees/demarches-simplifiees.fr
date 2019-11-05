class User < ApplicationRecord
  include EmailSanitizableConcern

  enum loged_in_with_france_connect: {
    particulier: 'particulier',
    entreprise: 'entreprise'
  }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :async,
    :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable

  has_many :dossiers, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :dossiers_invites, through: :invites, source: :dossier
  has_many :feedbacks, dependent: :destroy
  has_one :france_connect_information, dependent: :destroy
  belongs_to :instructeur
  belongs_to :administrateur

  accepts_nested_attributes_for :france_connect_information

  default_scope { eager_load(:instructeur, :administrateur) }

  before_validation -> { sanitize_email(:email) }

  # Callback provided by Devise
  def after_confirmation
    link_invites!
  end

  def owns?(dossier)
    dossier.user_id == id
  end

  def invite?(dossier_id)
    invites.pluck(:dossier_id).include?(dossier_id.to_i)
  end

  def owns_or_invite?(dossier)
    owns?(dossier) || invite?(dossier.id)
  end

  def invite!
    UserMailer.invite_instructeur(self, set_reset_password_token).deliver_later
  end

  def invite_administrateur!(administration_id)
    reset_password_token = nil

    if !active?
      reset_password_token = set_reset_password_token
    end

    AdministrationMailer.invite_admin(self, reset_password_token, administration_id).deliver_later
  end

  def remind_invitation!
    reset_password_token = set_reset_password_token

    AdministrateurMailer.activate_before_expiration(self, reset_password_token).deliver_later
  end

  def self.create_or_promote_to_instructeur(email, password, administrateurs: [])
    user = User
      .create_with(password: password, confirmed_at: Time.zone.now)
      .find_or_create_by(email: email)

    if user.valid?
      if user.instructeur_id.nil?
        user.create_instructeur!
      end

      user.instructeur.administrateurs << administrateurs
    end

    user
  end

  def self.create_or_promote_to_administrateur(email, password)
    user = User.create_or_promote_to_instructeur(email, password)

    if user.valid? && user.administrateur_id.nil?
      user.create_administrateur!(email: email)
    end

    user
  end

  def flipper_id
    "User:#{id}"
  end

  def active?
    last_sign_in_at.present?
  end

  private

  def link_invites!
    Invite.where(email: email).update_all(user_id: id)
  end
end
