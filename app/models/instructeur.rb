class Instructeur < ApplicationRecord
  self.ignored_columns = ['features', 'encrypted_password', 'reset_password_token', 'reset_password_sent_at', 'remember_created_at', 'sign_in_count', 'current_sign_in_at', 'last_sign_in_at', 'current_sign_in_ip', 'last_sign_in_ip', 'failed_attempts', 'unlock_token', 'locked_at']
  include EmailSanitizableConcern

  has_and_belongs_to_many :administrateurs

  before_validation -> { sanitize_email(:email) }

  has_many :assign_to, dependent: :destroy
  has_many :groupe_instructeurs, through: :assign_to
  has_many :procedures, through: :groupe_instructeurs

  has_many :assign_to_with_email_notifications, -> { with_email_notifications }, class_name: 'AssignTo', inverse_of: :instructeur
  has_many :groupe_instructeur_with_email_notifications, through: :assign_to_with_email_notifications, source: :groupe_instructeur

  has_many :dossiers, -> { state_not_brouillon }, through: :groupe_instructeurs
  has_many :follows, -> { active }, inverse_of: :instructeur
  has_many :previous_follows, -> { inactive }, class_name: 'Follow', inverse_of: :instructeur
  has_many :followed_dossiers, through: :follows, source: :dossier
  has_many :previously_followed_dossiers, -> { distinct }, through: :previous_follows, source: :dossier
  has_many :avis
  has_many :dossiers_from_avis, through: :avis, source: :dossier
  has_many :trusted_device_tokens

  has_one :user

  def visible_procedures
    procedures.merge(Procedure.avec_lien.or(Procedure.archivees))
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
      .map { |procedure| procedure.procedure_overview(start_date) }
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

  def notifications_for_procedure(procedure, state = :en_cours)
    dossiers = case state
    when :termine
      procedure.defaut_groupe_instructeur.dossiers.termine
    when :not_archived
      procedure.defaut_groupe_instructeur.dossiers.not_archived
    when :all
      procedure.defaut_groupe_instructeur.dossiers
    else
      procedure.defaut_groupe_instructeur.dossiers.en_cours
    end

    dossiers_id_with_notifications(dossiers)
  end

  def notifications_per_procedure(state = :en_cours)
    dossiers = case state
    when :termine
      Dossier.termine
    when :not_archived
      Dossier.not_archived
    else
      Dossier.en_cours
    end

    Dossier.joins(:groupe_instructeur).where(id: dossiers_id_with_notifications(dossiers)).group('groupe_instructeurs.procedure_id').count
  end

  def create_trusted_device_token
    trusted_device_token = trusted_device_tokens.create
    trusted_device_token.token
  end

  def dossiers_id_with_notifications(dossiers)
    dossiers = dossiers.followed_by(self)

    updated_demandes = dossiers
      .joins(:champs)
      .where('champs.updated_at > follows.demande_seen_at')

    updated_annotations = dossiers
      .joins(:champs_private)
      .where('champs.updated_at > follows.annotations_privees_seen_at')

    updated_avis = dossiers
      .joins(:avis)
      .where('avis.updated_at > follows.avis_seen_at')

    updated_messagerie = dossiers
      .joins(:commentaires)
      .where('commentaires.updated_at > follows.messagerie_seen_at')
      .where.not(commentaires: { email: OLD_CONTACT_EMAIL })
      .where.not(commentaires: { email: CONTACT_EMAIL })

    [
      updated_demandes,
      updated_annotations,
      updated_avis,
      updated_messagerie
    ].flat_map { |query| query.distinct.ids }.uniq
  end

  def mark_tab_as_seen(dossier, tab)
    attributes = {}
    attributes["#{tab}_seen_at"] = Time.zone.now
    Follow.where(instructeur: self, dossier: dossier).update_all(attributes)
  end

  def young_login_token?
    trusted_device_token = trusted_device_tokens.order(created_at: :desc).first
    trusted_device_token&.token_young?
  end

  def email_notification_data
    groupe_instructeur_with_email_notifications
      .reduce([]) do |acc, groupe|

      procedure = groupe.procedure

      h = {
        nb_en_construction: groupe.dossiers.en_construction.count,
        nb_notification: notifications_for_procedure(procedure, :all).count
      }

      if h[:nb_en_construction] > 0 || h[:nb_notification] > 0
        h[:procedure_id] = procedure.id
        h[:procedure_libelle] = procedure.libelle
        acc << h
      end

      acc
    end
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
