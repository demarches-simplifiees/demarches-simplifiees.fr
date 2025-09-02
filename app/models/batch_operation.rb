# frozen_string_literal: true

class BatchOperation < ApplicationRecord
  enum :operation, {
    accepter: 'accepter',
    refuser: 'refuser',
    classer_sans_suite: 'classer_sans_suite',
    archiver: 'archiver',
    desarchiver: 'desarchiver',
    follow: 'follow',
    passer_en_instruction: 'passer_en_instruction',
    repousser_expiration: 'repousser_expiration',
    repasser_en_construction: 'repasser_en_construction',
    restaurer: 'restaurer',
    unfollow: 'unfollow',
    supprimer: 'supprimer',
    create_avis: 'create_avis',
    create_commentaire: 'create_commentaire'
  }

  has_many :dossiers, dependent: :nullify
  has_many :dossier_operations, class_name: 'DossierBatchOperation', dependent: :destroy
  has_many :groupe_instructeurs, through: :dossier_operations
  belongs_to :instructeur

  store_accessor :payload, :motivation, :justificatif_motivation, :emails, :introduction, :question_label, :introduction_file, :confidentiel, :body, :piece_jointe

  validates :operation, presence: true

  before_create :build_operations

  RETENTION_DURATION = 4.hours
  MAX_DUREE_GENERATION = 24.hours

  scope :stale, lambda {
    where.not(finished_at: nil)
      .where(updated_at: ...(Time.zone.now - RETENTION_DURATION))
  }

  scope :stuck, lambda {
    where(finished_at: nil)
      .where(updated_at: ...(Time.zone.now - MAX_DUREE_GENERATION))
  }

  def dossiers_safe_scope(dossier_ids = self.dossier_ids)
    query = instructeur
      .dossiers
      .where(id: dossier_ids)
    case operation
    when BatchOperation.operations.fetch(:archiver) then
      query.visible_by_administration.not_archived.state_termine
    when BatchOperation.operations.fetch(:desarchiver) then
      query.visible_by_administration.archived.state_termine
    when BatchOperation.operations.fetch(:passer_en_instruction) then
      query.visible_by_administration.state_en_construction
    when BatchOperation.operations.fetch(:accepter) then
      query.visible_by_administration.state_en_instruction
    when BatchOperation.operations.fetch(:refuser) then
      query.visible_by_administration.state_en_instruction
    when BatchOperation.operations.fetch(:classer_sans_suite) then
      query.visible_by_administration.state_en_instruction
    when BatchOperation.operations.fetch(:follow) then
      query.visible_by_administration.without_followers.en_cours
    when BatchOperation.operations.fetch(:repousser_expiration) then
      query.visible_by_administration.termine_or_en_construction_close_to_expiration
    when BatchOperation.operations.fetch(:repasser_en_construction) then
      query.visible_by_administration.state_en_instruction
    when BatchOperation.operations.fetch(:unfollow) then
      query.visible_by_administration.with_followers.en_cours
    when BatchOperation.operations.fetch(:supprimer) then
      query.visible_by_administration.state_termine
    when BatchOperation.operations.fetch(:restaurer) then
      query.hidden_by_administration
    when BatchOperation.operations.fetch(:create_avis) then
      query.visible_by_administration.state_not_termine
    when BatchOperation.operations.fetch(:create_commentaire) then
      query.visible_by_administration
    end
  end

  def enqueue_all
    dossiers_safe_scope # later in batch .
      .map { |dossier| BatchOperationProcessOneJob.perform_later(self, dossier) }
  end

  def process_one(dossier)
    case operation
    when BatchOperation.operations.fetch(:archiver)
      dossier.archiver!(instructeur)
    when BatchOperation.operations.fetch(:desarchiver)
      dossier.desarchiver!
    when BatchOperation.operations.fetch(:passer_en_instruction)
      dossier.passer_en_instruction!(instructeur: instructeur)
    when BatchOperation.operations.fetch(:accepter)
      dossier.accepter!(instructeur: instructeur, motivation: motivation, justificatif: justificatif_motivation)
    when BatchOperation.operations.fetch(:refuser)
      dossier.refuser!(instructeur: instructeur, motivation: motivation, justificatif: justificatif_motivation)
    when BatchOperation.operations.fetch(:classer_sans_suite)
      dossier.classer_sans_suite!(instructeur: instructeur, motivation: motivation, justificatif: justificatif_motivation)
    when BatchOperation.operations.fetch(:follow)
      instructeur.follow(dossier)
    when BatchOperation.operations.fetch(:repousser_expiration)
      dossier.extend_conservation(1.month)
    when BatchOperation.operations.fetch(:repasser_en_construction)
      dossier.repasser_en_construction!(instructeur: instructeur)
    when BatchOperation.operations.fetch(:unfollow)
      instructeur.unfollow(dossier)
    when BatchOperation.operations.fetch(:supprimer)
      dossier.hide_and_keep_track!(instructeur, :instructeur_request)
    when BatchOperation.operations.fetch(:restaurer)
      dossier.restore(instructeur)
    when BatchOperation.operations.fetch(:create_avis)
      CreateAvisService.call(
        dossier: dossier,
        instructeur_or_expert: instructeur,
        params: {
          emails: emails || [],
          introduction: introduction,
          introduction_file: introduction_file,
          confidentiel: confidentiel,
          invite_linked_dossiers: payload['invite_linked_dossiers'],
          question_label: question_label
        }.with_indifferent_access
      )
    when BatchOperation.operations.fetch(:create_commentaire)
      CommentaireService.create(instructeur, dossier, { email: dossier.user.email, body:, piece_jointe: })
    end
  end

  def track_processed_dossier(success, dossier)
    dossiers.delete(dossier)
    touch(:run_at) if called_for_first_time?
    touch(:finished_at)

    if success
      dossier_operation(dossier).done!
    else
      dossier_operation(dossier).fail!
    end
  end

  # when an instructeur want to create a batch from his interface,
  #   another one might have run something on one of the dossier
  #   we use this approach to create a batch with given dossiers safely
  def self.safe_create!(params)
    transaction do
      instance = new(params)
      instance.dossiers = instance.dossiers_safe_scope(params[:dossier_ids])
        .not_having_batch_operation
      if instance.dossiers.present?
        instance.save!
        BatchOperationEnqueueAllJob.perform_later(instance)
        instance
      end
    end
  end

  def called_for_first_time?
    run_at.nil?
  end

  def total_count
    dossier_operations.size
  end

  def success_count
    dossier_operations.success.size
  end

  def errors?
    dossier_operations.error.present?
  end

  def finished_at
    dossiers.empty? ? super : nil
  end

  private

  def dossier_operation(dossier)
    dossier_operations.find_by!(dossier:)
  end

  def build_operations
    dossier_operations.build(dossiers.map { { dossier: _1 } })
  end
end
