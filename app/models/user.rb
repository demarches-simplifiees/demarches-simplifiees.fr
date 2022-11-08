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
#  team_account                 :boolean          default(FALSE)
#  unconfirmed_email            :text
#  unlock_token                 :string
#  created_at                   :datetime
#  updated_at                   :datetime
#  requested_merge_into_id      :bigint
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
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable

  # We should never cascade delete dossiers. In normal case we call delete_and_keep_track_dossiers
  # before deleting a user (which dissociate dossiers from the user).
  # Destroying a user with dossier is always a mistake.
  has_many :dossiers, dependent: :restrict_with_exception
  has_many :targeted_user_links, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :dossiers_invites, through: :invites, source: :dossier
  has_many :deleted_dossiers
  has_many :merge_logs, dependent: :destroy
  has_many :requested_merge_from, class_name: 'User', dependent: :nullify, inverse_of: :requested_merge_into, foreign_key: :requested_merge_into_id

  has_one :france_connect_information, dependent: :destroy
  has_one :instructeur, dependent: :destroy
  has_one :administrateur, dependent: :destroy
  has_one :expert, dependent: :destroy
  belongs_to :requested_merge_into, class_name: 'User', optional: true

  accepts_nested_attributes_for :france_connect_information

  default_scope { eager_load(:instructeur, :administrateur, :expert) }
  scope :marked_as_team_account, -> { where('email ilike ?', "%@beta.gouv.fr") }
  before_validation -> { sanitize_email(:email) }

  validate :does_not_merge_on_self, if: :requested_merge_into_id_changed?

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
      if user.instructeur.nil?
        user.create_instructeur!
        user.update(france_connect_information: nil)
      end

      user.instructeur.administrateurs << administrateurs
    end

    user
  end

  def self.create_or_promote_to_administrateur(email, password)
    user = User.create_or_promote_to_instructeur(email, password)

    if user.valid? && user.administrateur.nil?
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
      if user.expert.nil?
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
    administrateur.present?
  end

  def instructeur?
    instructeur.present?
  end

  def expert?
    expert.present?
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
      # delete invites
      Invite.where(dossier: dossiers).destroy_all

      # delete dossiers brouillon
      dossiers.state_brouillon.each do |dossier|
        dossier.hide_and_keep_track!(dossier.user, :user_removed)
      end
      dossiers.state_brouillon.find_each(&:purge_discarded)

      # delete dossiers en_construction
      dossiers.state_en_construction.each do |dossier|
        dossier.hide_and_keep_track!(dossier.user, :user_removed)
      end
      dossiers.state_en_construction.find_each(&:purge_discarded)

      # delete dossiers terminé
      dossiers.state_termine.each do |dossier|
        dossier.hide_and_keep_track!(dossier.user, :user_removed)
      end
      dossiers.update_all(deleted_user_email_never_send: email, user_id: nil, dossier_transfer_id: nil)

      destroy!
    end
  end

  def merge(old_user)
    raise "Merging same user, no way" if old_user.id == self.id
    transaction do
      old_user.dossiers.update_all(user_id: id)
      old_user.invites.update_all(user_id: id)
      old_user.merge_logs.update_all(user_id: id)
      old_user.targeted_user_links.update_all(user_id: id)

      # Move or merge old user's roles to the user
      [
        [old_user.instructeur, instructeur],
        [old_user.expert, expert],
        [old_user.administrateur, administrateur]
      ].each do |old_role, targeted_role|
        if targeted_role.nil?
          old_role&.update(user: self)
        else
          targeted_role.merge(old_role)
        end
      end
      # (Ensure the old user doesn't reference its former roles anymore)
      old_user.reload

      merge_logs.create(from_user_id: old_user.id, from_user_email: old_user.email)
      old_user.destroy
    end
  end

  def ask_for_merge(requested_user)
    if update(requested_merge_into: requested_user)
      UserMailer.ask_for_merge(self, requested_user.email).deliver_later
      return true
    else
      return false
    end
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  private

  def does_not_merge_on_self
    return if requested_merge_into_id != self.id
    errors.add(:requested_merge_into, :same)
  end

  def link_invites!
    Invite.where(email: email).update_all(user_id: id)
  end
end
