class Gestionnaire < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :administrateurs

  has_many :assign_to, dependent: :destroy
  has_many :procedures, through: :assign_to
  has_many :dossiers, -> { state_not_brouillon }, through: :procedures
  has_many :follows
  has_many :followed_dossiers, through: :follows, source: :dossier
  has_many :avis
  has_many :dossiers_from_avis, through: :avis, source: :dossier

  include CredentialsSyncableConcern

  def visible_procedures
    procedures.publiees_ou_archivees
  end

  def can_view_dossier?(dossier_id)
    avis.where(dossier_id: dossier_id).any? ||
      dossiers.where(id: dossier_id).any?
  end

  def follow(dossier)
    return if follow?(dossier)

    followed_dossiers << dossier
  end

  def unfollow(dossier)
    followed_dossiers.delete(dossier)
  end

  def follow?(dossier)
    followed_dossiers.include?(dossier)
  end

  def assigned_on_procedure?(procedure_id)
    procedures.find_by(id: procedure_id).present?
  end

  def assign_to_procedure(procedure)
    begin
      procedures << procedure
      true
    rescue ActiveRecord::RecordNotUnique
      false
    end
  end

  def remove_from_procedure(procedure)
    !!(procedure.in?(procedures) && procedures.destroy(procedure))
  end

  def last_week_overview
    start_date = DateTime.now.beginning_of_week

    active_procedure_overviews = procedures
      .publiees
      .map { |procedure| procedure.procedure_overview(start_date) }
      .select(&:had_some_activities?)

    if active_procedure_overviews.count == 0
      nil
    else
      {
        start_date: start_date,
        procedure_overviews: active_procedure_overviews,
      }
    end
  end

  def procedure_presentation_for_procedure_id(procedure_id)
    assign_to.find_by(procedure_id: procedure_id).procedure_presentation_or_default
  end

  def notifications_for_dossier(dossier)
    follow = Follow
      .includes(dossier: [:champs, :avis, :commentaires])
      .find_by(gestionnaire: self, dossier: dossier)

    if follow.present?
      # retirer le seen_at.present? une fois la contrainte de presence en base (et les migrations ad hoc)
      champs_publiques = follow.demande_seen_at.present? &&
        follow.dossier.champs.updated_since?(follow.demande_seen_at).any?

      pieces_justificatives = follow.demande_seen_at.present? &&
        follow.dossier.pieces_justificatives.updated_since?(follow.demande_seen_at).any?

      demande = champs_publiques || pieces_justificatives

      annotations_privees = follow.annotations_privees_seen_at.present? &&
        follow.dossier.champs_private.updated_since?(follow.annotations_privees_seen_at).any?

      avis_notif = follow.avis_seen_at.present? &&
        follow.dossier.avis.updated_since?(follow.avis_seen_at).any?

      messagerie = follow.messagerie_seen_at.present? &&
        dossier.commentaires
          .where.not(email: 'contact@tps.apientreprise.fr')
          .where.not(email: 'contact@demarches-simplifiees.fr')
          .updated_since?(follow.messagerie_seen_at).any?

      annotations_hash(demande, annotations_privees, avis_notif, messagerie)
    else
      annotations_hash(false, false, false, false)
    end
  end

  def notifications_for_procedure(procedure, state = :en_cours)
    dossiers = case state
    when :termine
      procedure.dossiers.termine
    when :not_archived
      procedure.dossiers.not_archived
    else
      procedure.dossiers.en_cours
    end.followed_by(self)

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
    end.followed_by(self)

    Dossier.where(id: dossiers_id_with_notifications(dossiers)).group(:procedure_id).count
  end

  def mark_tab_as_seen(dossier, tab)
    attributes = {}
    attributes["#{tab}_seen_at"] = DateTime.now
    Follow.where(gestionnaire: self, dossier: dossier).update_all(attributes)
  end

  private

  def valid_couple_table_attr? table, column
    couples = [
      {
        table: :dossier,
        column: :dossier_id
      },
      {
        table: :procedure,
        column: :libelle
      },
      {
        table: :etablissement,
        column: :siret
      },
      {
        table: :entreprise,
        column: :raison_sociale
      },
      {
        table: :dossier,
        column: :state
      }
    ]

    couples.include?({ table: table, column: column })
  end

  def annotations_hash(demande, annotations_privees, avis, messagerie)
    {
      demande: demande,
      annotations_privees: annotations_privees,
      avis: avis,
      messagerie: messagerie
    }
  end

  def dossiers_id_with_notifications(dossiers)
    updated_demandes = dossiers
      .joins(:champs)
      .where('champs.updated_at > follows.demande_seen_at')

    updated_pieces_justificatives = dossiers
      .joins(:pieces_justificatives)
      .where('pieces_justificatives.updated_at > follows.demande_seen_at')

    updated_annotations = dossiers
      .joins(:champs_private)
      .where('champs.updated_at > follows.annotations_privees_seen_at')

    updated_avis = dossiers
      .joins(:avis)
      .where('avis.updated_at > follows.avis_seen_at')

    updated_messagerie = dossiers
      .joins(:commentaires)
      .where('commentaires.updated_at > follows.messagerie_seen_at')
      .where.not(commentaires: { email: 'contact@tps.apientreprise.fr' })
      .where.not(commentaires: { email: 'contact@demarches-simplifiees.fr' })

    [
      updated_demandes,
      updated_pieces_justificatives,
      updated_annotations,
      updated_avis,
      updated_messagerie
    ].flat_map { |query| query.distinct.ids }.uniq
  end
end
