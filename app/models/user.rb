class User < ApplicationRecord
  include CredentialsSyncableConcern
  include EmailSanitizableConcern

  enum loged_in_with_france_connect: {
    particulier: 'particulier',
    entreprise: 'entreprise'
  }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :async,
    :recoverable, :rememberable, :trackable, :validatable, :confirmable

  has_many :dossiers, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :dossiers_invites, through: :invites, source: :dossier
  has_many :piece_justificative, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_one :france_connect_information, dependent: :destroy

  accepts_nested_attributes_for :france_connect_information

  before_validation -> { sanitize_email(:email) }

  # Callback provided by Devise
  def after_confirmation
    link_invites!
  end

  def self.find_for_france_connect(email, siret)
    user = User.find_by(email: email)
    if user.nil?
      return User.create(email: email, password: Devise.friendly_token[0, 20], siret: siret)
    else
      user.update(siret: siret)
      user
    end
  end

  def loged_in_with_france_connect?
    loged_in_with_france_connect.present?
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

  private

  def link_invites!
    Invite.where(email: email).update_all(user_id: id)
  end
end
