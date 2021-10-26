# == Schema Information
#
# Table name: users
#
#  id                           :integer          not null, primary key
#  confirmation_sent_at         :datetime
#  confirmation_token           :string
#  confirmed_at                 :datetime
#  current_sign_in_at           :datetime
#  current_sign_in_ip           :string
#  email                        :string           default(""), not null
#  encrypted_password           :string           default(""), not null
#  failed_attempts              :integer          default(0), not null
#  last_sign_in_at              :datetime
#  last_sign_in_ip              :string
#  locale                       :string
#  locked_at                    :datetime
#  loged_in_with_france_connect :string           default(NULL)
#  remember_created_at          :datetime
#  reset_password_sent_at       :datetime
#  reset_password_token         :string
#  sign_in_count                :integer          default(0), not null
#  siret                        :string
#  unconfirmed_email            :text
#  unlock_token                 :string
#  created_at                   :datetime
#  updated_at                   :datetime
#  administrateur_id            :bigint
#  expert_id                    :bigint
#  instructeur_id               :bigint
#
class User < ApplicationRecord
  include EmailSanitizableConcern
  include PasswordComplexityConcern

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
  has_many :deleted_dossiers
  has_one :france_connect_information, dependent: :destroy
  belongs_to :instructeur, optional: true
  belongs_to :administrateur, optional: true
  belongs_to :expert, optional: true

  accepts_nested_attributes_for :france_connect_information

  default_scope { eager_load(:instructeur, :administrateur, :expert) }

  before_validation -> { sanitize_email(:email) }

  def validate_password_complexity?
    administrateur?
  end

  # Override of Devise::Models::Confirmable#send_confirmation_instructions
  def send_confirmation_instructions
    unless @raw_confirmation_token
      generate_confirmation_token!
    end

    opts = pending_reconfirmation? ? { to: unconfirmed_email } : {}

    # Make our procedure_after_confirmation available to the Mailer
    opts[:procedure_after_confirmation] = CurrentConfirmation.procedure_after_confirmation

    send_devise_notification(:confirmation_instructions, @raw_confirmation_token, opts)
  end

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
    AdministrationMailer.invite_admin(self, set_reset_password_token, administration_id).deliver_later
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
        user.update(france_connect_information: nil)
      end

      user.instructeur.administrateurs << administrateurs
    end

    user
  end

  def self.create_or_promote_to_administrateur(email, password)
    user = User.create_or_promote_to_instructeur(email, password)

    if user.valid? && user.administrateur_id.nil?
      user.create_administrateur!
      user.update(france_connect_information: nil)
    end

    user
  end

  def self.create_or_promote_to_expert(email, password)
    user = User
      .create_with(password: password, confirmed_at: Time.zone.now)
      .find_or_create_by(email: email)

    if user.valid?
      if user.expert_id.nil?
        user.create_expert!
      end
    end

    user
  end

  def flipper_id
    "User:#{id}"
  end

  def active?
    last_sign_in_at.present?
  end

  def administrateur?
    administrateur_id.present?
  end

  def instructeur?
    instructeur_id.present?
  end

  def expert?
    expert_id.present?
  end

  def can_france_connect?
    !administrateur? && !instructeur?
  end

  def can_be_deleted?
    !administrateur? && !instructeur? && !expert?
  end

  def delete_and_keep_track_dossiers(administration)
    if !can_be_deleted?
      raise "Cannot delete this user because they are also instructeur, expert or administrateur"
    end

    transaction do
      Invite.where(dossier: dossiers.with_discarded).destroy_all
      dossiers.state_en_construction.each do |dossier|
        dossier.discard_and_keep_track!(administration, :user_removed)
      end
      DossierOperationLog.where(dossier: dossiers.with_discarded.discarded).not_deletion.destroy_all
      dossiers.with_discarded.discarded.destroy_all
      dossiers.update_all(deleted_user_email_never_send: email, user_id: nil, dossier_transfer_id: nil)
      destroy!
    end
  end

  private

  def link_invites!
    Invite.where(email: email).update_all(user_id: id)
  end
end
