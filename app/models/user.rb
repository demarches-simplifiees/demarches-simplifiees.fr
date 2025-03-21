class User < ApplicationRecord
  include DomainMigratableConcern
  include EmailSanitizableConcern
  include PasswordComplexityConcern

  enum loged_in_with_france_connect: {
    particulier: 'particulier',
    entreprise: 'entreprise',
    sipf: 'sipf',
    facebook: 'facebook',
    google: 'google',
    microsoft: 'microsoft',
    yahoo: 'yahoo',
    tatou: 'tatou'
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
  has_many :france_connect_informations, dependent: :destroy

  has_one :instructeur, dependent: :destroy
  has_one :administrateur, dependent: :destroy
  has_one :gestionnaire, dependent: :destroy
  has_one :expert, dependent: :destroy
  belongs_to :requested_merge_into, class_name: 'User', optional: true

  accepts_nested_attributes_for :france_connect_informations

  default_scope { eager_load(:instructeur, :administrateur, :expert) }

  before_validation -> { sanitize_email(:email) }
  validate :does_not_merge_on_self, if: :requested_merge_into_id_changed?

  before_validation :remove_devise_email_format_validator
  # plug our custom validation a la devise (same options) https://github.com/heartcombo/devise/blob/main/lib/devise/models/validatable.rb#L30
  validates :email, strict_email: true, allow_blank: true, if: :devise_will_save_change_to_email?

  def validate_password_complexity?
    min_password_complexity.positive?
  end

  def min_password_complexity
    if administrateur?
      PASSWORD_COMPLEXITY_FOR_ADMIN
    elsif instructeur?
      PASSWORD_COMPLEXITY_FOR_INSTRUCTEUR
    else
      PASSWORD_COMPLEXITY_FOR_USER
    end
  end

  # Override of Devise::Models::Confirmable#send_confirmation_instructions
  def send_confirmation_instructions
    unless @raw_confirmation_token
      generate_confirmation_token!
    end

    opts = pending_reconfirmation? ? { to: unconfirmed_email } : {}

    # Make our procedure_after_confirmation available to the Mailer
    opts[:procedure_after_confirmation] = CurrentConfirmation.procedure_after_confirmation
    opts[:prefill_token] = CurrentConfirmation.prefill_token

    send_devise_notification(:confirmation_instructions, @raw_confirmation_token, opts)
  end

  # Callback provided by Devise
  def after_confirmation
    update!(email_verified_at: Time.zone.now)
    link_invites!
  end

  def owns?(dossier)
    dossier.user_id == id
  end

  def invite?(dossier)
    invites.exists?(dossier:)
  end

  def owns_or_invite?(dossier)
    owns?(dossier) || invite?(dossier)
  end

  def invite_instructeur!
    UserMailer.invite_instructeur(self, set_reset_password_token).deliver_later
  end

  def invite_gestionnaire!(groupe_gestionnaire)
    UserMailer.invite_gestionnaire(self, set_reset_password_token, groupe_gestionnaire).deliver_later
  end

  def invite_administrateur!
    AdministrationMailer.invite_admin(self, set_reset_password_token).deliver_later
  end

  def remind_invitation!
    reset_password_token = set_reset_password_token

    AdministrateurMailer.activate_before_expiration(self, reset_password_token).deliver_later
  end

  def self.create_or_promote_to_instructeur(email, password, administrateurs: [], agent_connect: false)
    if agent_connect
      user = User
        .create_with(password: password, confirmed_at: Time.zone.now, email_verified_at: Time.zone.now)
        .find_or_create_by(email: email)
    else
      user = User
        .create_with(password: password, confirmed_at: Time.zone.now)
        .find_or_create_by(email: email)
    end

    if user.valid?
      if user.instructeur.nil?
        user.create_instructeur!
        user.france_connect_informations.delete_all
      end

      user.instructeur.administrateurs << administrateurs
    end

    user
  end

  def self.create_or_promote_to_gestionnaire(email, password)
    user = User.create_or_promote_to_administrateur(email, password)

    if user.valid? && user.gestionnaire.nil?
      user.create_gestionnaire!
    end

    user
  end

  def self.create_or_promote_to_administrateur(email, password)
    user = User.create_or_promote_to_instructeur(email, password)

    if user.valid? && user.administrateur.nil?
      user.create_administrateur!
      user.france_connect_informations.delete_all
      AdminUpdateDefaultZonesJob.perform_later(user.administrateur)
    end

    user
  end

  def self.create_or_promote_to_expert(email, password)
    user = User
      .create_with(password: password, confirmed_at: Time.zone.now, email_verified_at: Time.zone.now)
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

  def gestionnaire?
    gestionnaire.present?
  end

  def expert?
    expert.present?
  end

  def can_france_connect?
    !administrateur? && !instructeur?
  end

  def can_openid_connect?(provider)
    can_france_connect? || provider == 'microsoft'
  end

  def france_connected_with_one_identity?
    # pf fci may be known while the user logged with regular password
    # ==> adds loged_in_with_france_connect
    loged_in_with_france_connect.present? && france_connect_informations.size == 1
  end

  def can_be_deleted?
    !administrateur? && !instructeur? && !expert?
  end

  def delete_and_keep_track_dossiers_also_delete_user(super_admin, reason:)
    if !can_be_deleted?
      raise "Cannot delete this user because they are also instructeur, expert or administrateur"
    end

    transaction do
      # delete invites
      Invite.where(dossier: dossiers).destroy_all

      delete_and_keep_track_dossiers(super_admin, reason: :user_removed)
      destroy!
    end
  end

  def delete_and_keep_track_dossiers(super_admin, reason:)
    transaction do
      # delete dossiers brouillon
      dossiers.state_brouillon.each do |dossier|
        dossier.hide_and_keep_track!(dossier.user, reason)
      end
      dossiers.state_brouillon.find_each(&:purge_discarded)

      # delete dossiers en_construction
      dossiers.state_en_construction.each do |dossier|
        dossier.hide_and_keep_track!(dossier.user, reason)
      end
      dossiers.state_en_construction.find_each(&:purge_discarded)

      # delete dossiers terminé
      dossiers.state_termine.each do |dossier|
        dossier.hide_and_keep_track!(dossier.user, reason)
      end
      dossiers.update_all(deleted_user_email_never_send: email, user_id: nil, dossier_transfer_id: nil)
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

  def active_for_authentication?
    super && blocked_at.nil?
  end

  def unverified_email? = !email_verified_at?

  private

  def does_not_merge_on_self
    return if requested_merge_into_id != self.id
    errors.add(:requested_merge_into, :same)
  end

  def link_invites!
    Invite.where(email: email).update_all(user_id: id)
  end

  # we just want to remove the devise format validator
  #   https://github.com/heartcombo/devise/blob/main/lib/devise/models/validatable.rb#L30
  def remove_devise_email_format_validator
    _validators[:email]&.reject! { _1.is_a?(ActiveModel::Validations::FormatValidator) }
    _validate_callbacks.each do |callback|
      next if !callback.filter.is_a?(ActiveModel::Validations::FormatValidator)
      next if !callback.filter.attributes.include? :email

      callback.filter.attributes.delete(:email)
    end
  end
end
