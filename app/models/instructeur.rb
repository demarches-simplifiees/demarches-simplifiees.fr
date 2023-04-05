# == Schema Information
#
# Table name: instructeurs
#
#  id                       :integer          not null, primary key
#  bypass_email_login_token :boolean          default(FALSE), not null
#  encrypted_login_token    :text
#  login_token_created_at   :datetime
#  created_at               :datetime
#  updated_at               :datetime
#  agent_connect_id         :string
#  user_id                  :bigint           not null
#
class Instructeur < ApplicationRecord
  has_and_belongs_to_many :administrateurs

  has_many :assign_to, dependent: :destroy
  has_many :groupe_instructeurs, -> { order(:label) }, through: :assign_to
  has_many :unordered_groupe_instructeurs, through: :assign_to, source: :groupe_instructeur
  has_many :procedures, -> { distinct }, through: :unordered_groupe_instructeurs
  has_many :batch_operations, dependent: :nullify
  has_many :assign_to_with_email_notifications, -> { with_email_notifications }, class_name: 'AssignTo', inverse_of: :instructeur
  has_many :groupe_instructeur_with_email_notifications, through: :assign_to_with_email_notifications, source: :groupe_instructeur

  has_many :commentaires, inverse_of: :instructeur, dependent: :nullify
  has_many :dossiers, -> { state_not_brouillon }, through: :unordered_groupe_instructeurs
  has_many :follows, -> { active }, inverse_of: :instructeur
  has_many :previous_follows, -> { inactive }, class_name: 'Follow', inverse_of: :instructeur
  has_many :followed_dossiers, through: :follows, source: :dossier
  has_many :previously_followed_dossiers, -> { distinct }, through: :previous_follows, source: :dossier
  has_many :trusted_device_tokens, dependent: :destroy
  has_many :archives
  has_many :bulk_messages, dependent: :destroy

  belongs_to :user

  scope :with_instant_email_message_notifications, -> {
    includes(:assign_to).where(assign_tos: { instant_email_message_notifications_enabled: true })
  }

  scope :with_instant_email_dossier_notifications, -> {
    includes(:assign_to).where(assign_tos: { instant_email_dossier_notifications_enabled: true })
  }

  scope :with_instant_expert_avis_email_notifications_enabled, -> {
    includes(:assign_to).where(assign_tos: { instant_expert_avis_email_notifications_enabled: true })
  }

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
    if !procedure.defaut_groupe_instructeur.in?(groupe_instructeurs)
      groupe_instructeurs << procedure.defaut_groupe_instructeur
    end
  end

  NOTIFICATION_SETTINGS = [:daily_email_notifications_enabled, :instant_email_dossier_notifications_enabled, :instant_email_message_notifications_enabled, :weekly_email_notifications_enabled, :instant_expert_avis_email_notifications_enabled]

  def notification_settings(procedure_id)
    assign_to
      .joins(:groupe_instructeur)
      .find_by(groupe_instructeurs: { procedure_id: procedure_id })
      &.slice(*NOTIFICATION_SETTINGS) || {}
  end

  def last_week_overview
    start_date = Time.zone.now.beginning_of_week

    active_procedure_overviews = procedures
      .where(assign_tos: { weekly_email_notifications_enabled: true })
      .publiees
      .map { |procedure| procedure.procedure_overview(start_date, groupe_instructeurs) }
      .filter(&:had_some_activities?)

    if active_procedure_overviews.empty?
      nil
    else
      {
        start_date: start_date,
        procedure_overviews: active_procedure_overviews
      }
    end
  end

  def procedure_presentation_and_errors_for_procedure_id(procedure_id)
    assign_to
      .joins(:groupe_instructeur)
      .includes(:instructeur, :procedure)
      .find_by(groupe_instructeurs: { procedure_id: procedure_id })
      .procedure_presentation_or_default_and_errors
  end

  def notifications_for_dossier(dossier)
    follow = Follow
      .includes(dossier: [:champs_public, :champs_private, :avis, :commentaires])
      .find_by(instructeur: self, dossier: dossier)

    if follow.present?
      demande = follow.dossier.champs_public.updated_since?(follow.demande_seen_at).any? ||
        follow.dossier.groupe_instructeur_updated_at&.>(follow.demande_seen_at) ||
        dossier.identity_updated_at&.>(follow.demande_seen_at) ||
        false

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

  def notifications_for_groupe_instructeurs(groupe_instructeurs)
    Dossier
      .visible_by_administration
      .not_archived
      .where(groupe_instructeur: groupe_instructeurs)
      .merge(followed_dossiers)
      .with_notifications
      .pluck(:state, :id)
      .reduce({ termines: [], en_cours: [] }) do |acc, e|
        if Dossier::TERMINE.include?(e[0])
          acc[:termines] << e[1]
        elsif Dossier::EN_CONSTRUCTION_OU_INSTRUCTION.include?(e[0])
          acc[:en_cours] << e[1]
        end
        acc
      end
  end

  def procedure_ids_with_notifications(scope)
    groupe_instructeur_ids = Dossier
      .send(scope) # :en_cours or :termine (or any other Dossier scope)
      .merge(followed_dossiers)
      .visible_by_administration
      .with_notifications
      .select(:groupe_instructeur_id)

    GroupeInstructeur.where(id: groupe_instructeur_ids).pluck(:procedure_id)
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

      notifications = notifications_for_groupe_instructeurs([groupe.id])
      nb_notification = notifications[:en_cours].count + notifications[:termines].count

      h = {
        nb_en_construction: groupe.dossiers.visible_by_administration.en_construction.count,
        nb_en_instruction: groupe.dossiers.visible_by_administration.en_instruction.count,
        nb_accepted: Traitement.where(dossier: groupe.dossiers.accepte, processed_at: Time.zone.yesterday.beginning_of_day..Time.zone.yesterday.end_of_day).count,
        nb_notification: nb_notification
      }

      if h[:nb_en_construction] > 0 || h[:nb_notification] > 0
        h[:procedure_id] = procedure.id
        h[:procedure_libelle] = procedure.libelle
        acc << h
      end

      if h[:nb_en_instruction] > 0 || h[:nb_accepted] > 0
        [["en_instruction", h[:nb_en_instruction]], ["accepte", h[:nb_accepted]]].each do |state, count|
          if procedure&.declarative_with_state == state && count > 0
            h[:procedure_id] = procedure.id
            h[:procedure_libelle] = procedure.libelle
            acc << h
          end
        end
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

  # required to display feature flags field in manager
  def features
  end

  def flipper_id
    "Instructeur:#{id}"
  end

  def dossiers_count_summary(groupe_instructeur_ids)
    query = <<~EOF
      SELECT
        COUNT(DISTINCT dossiers.id) FILTER (where dossiers.hidden_by_administration_at IS NULL AND not archived AND dossiers.state in ('en_construction', 'en_instruction') AND follows.id IS NULL) AS a_suivre,
        COUNT(DISTINCT dossiers.id) FILTER (where dossiers.hidden_by_administration_at IS NULL AND not archived AND dossiers.state in ('en_construction', 'en_instruction') AND follows.instructeur_id = :instructeur_id) AS suivis,
        COUNT(DISTINCT dossiers.id) FILTER (where dossiers.hidden_by_administration_at IS NULL AND not archived AND dossiers.state in ('accepte', 'refuse', 'sans_suite')) AS traites,
        COUNT(DISTINCT dossiers.id) FILTER (where dossiers.hidden_by_administration_at IS NULL AND not archived) AS tous,
        COUNT(DISTINCT dossiers.id) FILTER (where dossiers.hidden_by_administration_at IS NULL AND archived) AS archives,
        COUNT(DISTINCT dossiers.id) FILTER (where dossiers.hidden_by_administration_at IS NOT NULL AND not archived AND dossiers.state in ('accepte', 'refuse', 'sans_suite')) AS supprimes_recemment,
        COUNT(DISTINCT dossiers.id) FILTER (where dossiers.hidden_by_administration_at IS NULL AND procedures.procedure_expires_when_termine_enabled
          AND (
            dossiers.state in ('accepte', 'refuse', 'sans_suite')
              AND dossiers.processed_at + dossiers.conservation_extension + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now
          ) OR (
            dossiers.state in ('en_construction')
              AND dossiers.en_construction_at + dossiers.conservation_extension + (duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now
          )
        ) AS expirant
      FROM dossiers
        INNER JOIN procedure_revisions
          ON procedure_revisions.id = dossiers.revision_id
        INNER JOIN procedures
          ON procedures.id = procedure_revisions.procedure_id
        LEFT OUTER JOIN follows
          ON  follows.dossier_id = dossiers.id
          AND follows.unfollowed_at IS NULL
      WHERE dossiers.state != 'brouillon'
        AND dossiers.groupe_instructeur_id in (:groupe_instructeur_ids)
        AND (dossiers.hidden_by_user_at IS NULL OR dossiers.state != 'en_construction')
    EOF

    sanitized_query = ActiveRecord::Base.sanitize_sql([
      query,
      instructeur_id: id,
      groupe_instructeur_ids: groupe_instructeur_ids,
      now: Time.zone.now,
      expires_in: Dossier::INTERVAL_BEFORE_EXPIRATION
    ])

    Dossier.connection.select_all(sanitized_query).first
  end

  def merge(old_instructeur)
    return if old_instructeur.nil?

    old_instructeur
      .assign_to
      .where.not(groupe_instructeur_id: assign_to.pluck(:groupe_instructeur_id))
      .update_all(instructeur_id: id)

    old_instructeur
      .follows
      .where.not(dossier_id: follows.pluck(:dossier_id))
      .update_all(instructeur_id: id)

    admin_with_new_instructeur, admin_without_new_instructeur = old_instructeur
      .administrateurs
      .partition { |admin| admin.instructeurs.exists?(id) }

    admin_without_new_instructeur.each do |admin|
      admin.instructeurs << self
      admin.instructeurs.delete(old_instructeur)
    end

    admin_with_new_instructeur.each do |admin|
      admin.instructeurs.delete(old_instructeur)
    end
    old_instructeur.commentaires.update_all(instructeur_id: id)
    old_instructeur.bulk_messages.update_all(instructeur_id: id)

    Avis
      .where(claimant_id: old_instructeur.id, claimant_type: Instructeur.name)
      .update_all(claimant_id: id)
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
