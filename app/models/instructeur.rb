class Instructeur < ApplicationRecord
  self.ignored_columns = ['email', 'features', 'encrypted_password', 'reset_password_token', 'reset_password_sent_at', 'remember_created_at', 'sign_in_count', 'current_sign_in_at', 'last_sign_in_at', 'current_sign_in_ip', 'last_sign_in_ip', 'failed_attempts', 'unlock_token', 'locked_at']

  has_and_belongs_to_many :administrateurs

  has_many :assign_to, dependent: :destroy
  has_many :groupe_instructeurs, through: :assign_to
  has_many :procedures, -> { distinct }, through: :groupe_instructeurs

  has_many :assign_to_with_email_notifications, -> { with_email_notifications }, class_name: 'AssignTo', inverse_of: :instructeur
  has_many :groupe_instructeur_with_email_notifications, through: :assign_to_with_email_notifications, source: :groupe_instructeur

  has_many :dossiers, -> { state_not_brouillon }, through: :groupe_instructeurs
  has_many :follows, -> { active }, inverse_of: :instructeur
  has_many :previous_follows, -> { inactive }, class_name: 'Follow', inverse_of: :instructeur
  has_many :followed_dossiers, through: :follows, source: :dossier
  has_many :previously_followed_dossiers, -> { distinct }, through: :previous_follows, source: :dossier
  has_many :avis
  has_many :dossiers_from_avis, through: :avis, source: :dossier
  has_many :trusted_device_tokens, dependent: :destroy

  has_one :user, dependent: :nullify

  default_scope { eager_load(:user) }

  def self.by_email(email)
    Instructeur.eager_load(:user).find_by(users: { email: email })
  end

  def email
    user.email
  end

  def follow(dossier)
    begin
      followed_dossiers << dossier
      # If the user tries to follow a dossier she already follows,
      # we just fail silently: it means the goal is already reached.
    rescue ActiveRecord::RecordNotUnique
      # Database uniqueness constraint
    rescue ActiveRecord::RecordInvalid => e
      # ActiveRecord validation
      raise unless e.record.errors.details.dig(:instructeur_id, 0, :error) == :taken
    end
  end

  def unfollow(dossier)
    f = follows.find_by(dossier: dossier)
    if f.present?
      f.update(unfollowed_at: Time.zone.now)
    end
  end

  def follow?(dossier)
    followed_dossiers.include?(dossier)
  end

  def assign_to_procedure(procedure)
    begin
      assign_to.create({
        procedure: procedure,
        groupe_instructeur: procedure.defaut_groupe_instructeur
      })
      true
    rescue ActiveRecord::RecordNotUnique
      false
    end
  end

  def remove_from_procedure(procedure)
    !!(procedure.defaut_groupe_instructeur.in?(groupe_instructeurs) && groupe_instructeurs.destroy(procedure.defaut_groupe_instructeur))
  end

  def last_week_overview
    start_date = Time.zone.now.beginning_of_week

    active_procedure_overviews = procedures
      .publiees
      .map { |procedure| procedure.procedure_overview(start_date, groupe_instructeurs) }
      .filter(&:had_some_activities?)

    if active_procedure_overviews.count == 0
      nil
    else
      {
        start_date: start_date,
        procedure_overviews: active_procedure_overviews
      }
    end
  end

  def procedure_presentation_and_errors_for_procedure_id(procedure_id)
    assign_to.joins(:groupe_instructeur).find_by(groupe_instructeurs: { procedure_id: procedure_id }).procedure_presentation_or_default_and_errors
  end

  def notifications_for_dossier(dossier)
    follow = Follow
      .includes(dossier: [:champs, :avis, :commentaires])
      .find_by(instructeur: self, dossier: dossier)

    if follow.present?
      demande = follow.dossier.champs.updated_since?(follow.demande_seen_at).any?

      annotations_privees = follow.dossier.champs_private.updated_since?(follow.annotations_privees_seen_at).any?

      avis_notif = follow.dossier.avis.updated_since?(follow.avis_seen_at).any?

      messagerie = dossier.commentaires
        .where.not(email: OLD_CONTACT_EMAIL)
        .where.not(email: CONTACT_EMAIL)
        .updated_since?(follow.messagerie_seen_at).any?

      annotations_hash(demande, annotations_privees, avis_notif, messagerie)
    else
      annotations_hash(false, false, false, false)
    end
  end

  def notifications_for_procedure(procedure, scope)
    target_groupes = groupe_instructeurs.where(procedure: procedure)

    Dossier
      .where(groupe_instructeur: target_groupes)
      .send(scope) # :en_cours or :termine or :not_archived (or any other Dossier scope)
      .merge(followed_dossiers)
      .with_notifications
  end

  def procedures_with_notifications(scope)
    dossiers = Dossier
      .send(scope) # :en_cours or :termine (or any other Dossier scope)
      .merge(followed_dossiers)
      .with_notifications

    Procedure
      .where(id: dossiers.joins(:groupe_instructeur)
        .select('groupe_instructeurs.procedure_id')
        .distinct)
      .distinct
  end

  def mark_tab_as_seen(dossier, tab)
    attributes = {}
    attributes["#{tab}_seen_at"] = Time.zone.now
    Follow.where(instructeur: self, dossier: dossier).update_all(attributes)
  end

  def email_notification_data
    groupe_instructeur_with_email_notifications
      .reduce([]) do |acc, groupe|

      procedure = groupe.procedure

      h = {
        nb_en_construction: groupe.dossiers.en_construction.count,
        nb_notification: notifications_for_procedure(procedure, :not_archived).count
      }

      if h[:nb_en_construction] > 0 || h[:nb_notification] > 0
        h[:procedure_id] = procedure.id
        h[:procedure_libelle] = procedure.libelle
        acc << h
      end

      acc
    end
  end

  def create_trusted_device_token
    trusted_device_token = trusted_device_tokens.create
    trusted_device_token.token
  end

  def young_login_token?
    trusted_device_token = trusted_device_tokens.order(created_at: :desc).first
    trusted_device_token&.token_young?
  end

  def can_be_deleted?
    user.administrateur.nil? && procedures.all? { |p| p.defaut_groupe_instructeur.instructeurs.count > 1 }
  end

  private

  def annotations_hash(demande, annotations_privees, avis, messagerie)
    {
      demande: demande,
      annotations_privees: annotations_privees,
      avis: avis,
      messagerie: messagerie
    }
  end
end
