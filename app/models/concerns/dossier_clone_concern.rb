# frozen_string_literal: true

module DossierCloneConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :parent_dossier, class_name: 'Dossier', optional: true
    has_many :cloned_dossiers, class_name: 'Dossier', foreign_key: :parent_dossier_id, dependent: :nullify, inverse_of: :parent_dossier

    belongs_to :editing_fork_origin, class_name: 'Dossier', optional: true
    has_many :editing_forks, -> { where(hidden_by_reason: nil) }, class_name: 'Dossier', foreign_key: :editing_fork_origin_id, dependent: :destroy, inverse_of: :editing_fork_origin
  end

  def find_or_create_editing_fork(user)
    find_editing_fork(user) || clone(user:, fork: true)
  end

  def find_editing_fork(user, rebase: true)
    fork = editing_forks.find_by(user:)
    fork = DossierPreloader.load_one(fork) if fork
    fork.rebase! if rebase && fork

    fork
  end

  def owner_editing_fork
    find_or_create_editing_fork(user).tap { DossierPreloader.load_one(_1) }
  end

  def destroy_editing_fork!
    if editing_fork?
      update!(hidden_by_administration_at: Time.current, hidden_by_reason: :stale_fork)
      DestroyRecordLaterJob.perform_later(self)
    end
  end

  def editing_fork?
    editing_fork_origin_id.present?
  end

  def with_editing_fork?
    editing_forks.present?
  end

  # TODO remove when all forks are gone
  def en_construction_for_editor?
    en_construction? || editing_fork?
  end

  def make_diff(editing_fork)
    origin_champs_index = project_champs_public_all.index_by(&:public_id)
    forked_champs_index = editing_fork.project_champs_public_all.index_by(&:public_id)
    updated_champs_index = editing_fork
      .project_champs_public_all
      .filter { _1.updated_at > editing_fork.created_at }
      .index_by(&:public_id)

    added = forked_champs_index.keys - origin_champs_index.keys
    removed = origin_champs_index.keys - forked_champs_index.keys
    updated = updated_champs_index.keys - added

    {
      added: added.map { forked_champs_index[_1] },
      updated: updated.map { forked_champs_index[_1] },
      removed: removed.map { origin_champs_index[_1] }
    }
  end

  def merge_fork(editing_fork)
    return false if invalid? || editing_fork.invalid?
    return false if revision_id > editing_fork.revision_id

    transaction do
      rebase!
      diff = make_diff(editing_fork)
      apply_diff(diff)

      changed_champs = diff.values.flatten
      update_champs_timestamps(changed_champs)
    end
    reload
    index_search_terms_later
    editing_fork.destroy_editing_fork!
  end

  def clone(user: nil, fork: false)
    dossier_attributes = [:autorisation_donnees, :revision_id]
    dossier_attributes += [:groupe_instructeur_id] if fork
    relationships = [:individual, :etablissement]

    discarded_row_ids = champs_on_main_stream
      .filter { _1.row? && _1.discarded? }
      .to_set(&:row_id)
    cloned_champs = champs_on_main_stream
      .reject { discarded_row_ids.member?(_1.row_id) }
      .index_by(&:id)
      .transform_values { [_1, _1.clone(fork)] }

    cloned_dossier = deep_clone(only: dossier_attributes, include: relationships) do |original, kopy|
      ClonePiecesJustificativesService.clone_attachments(original, kopy)

      if original.is_a?(Dossier)
        if fork
          kopy.editing_fork_origin = original
        else
          kopy.parent_dossier = original
        end

        kopy.user = user || original.user
        kopy.state = Dossier.states.fetch(:brouillon)
        kopy.champs = cloned_champs.values.map do |(_, champ)|
          champ.dossier = kopy
          champ
        end
      end
    end

    transaction do
      if fork
        cloned_dossier.save!(validate: false)
      else
        cloned_dossier.validate(:champs_public_value)
        cloned_dossier.save!
      end
      cloned_dossier.rebase!
    end

    if fork
      cloned_champs.values.each do |(original, champ)|
        champ.update_columns(created_at: original.created_at, updated_at: original.updated_at)
      end
    end

    cloned_dossier.index_search_terms_later if !fork
    cloned_dossier.reload
  end

  protected

  def forked_with_changes?
    if with_editing_fork?
      find_editing_fork(user, rebase: false)&.forked_with_changes?
    elsif forked_diff.present?
      forked_diff.values.any?(&:present?) || forked_groupe_instructeur_changed?
    end
  end

  def champ_forked_with_changes?(champ)
    if with_editing_fork?
      find_editing_fork(user, rebase: false)&.champ_forked_with_changes?(champ)
    elsif forked_diff.present?
      forked_diff.values.any? { |champs| champs.any? { _1.public_id == champ.public_id } }
    end
  end

  private

  def forked_diff
    @forked_diff ||= editing_fork? ? editing_fork_origin.make_diff(self) : nil
  end

  def forked_groupe_instructeur_changed?
    editing_fork_origin.groupe_instructeur_id != groupe_instructeur_id
  end

  def apply_diff(diff)
    added_row_ids = {}
    diff[:added].each do |champ|
      next if !champ.child?
      next if added_row_ids.key?(champ.row_id)
      added_row_ids[champ.row_id] = revision.parent_of(champ.type_de_champ)
    end

    removed_row_ids = {}
    diff[:removed].each do |champ|
      next if !champ.child?
      next if removed_row_ids.key?(champ.row_id)
      removed_row_ids[champ.row_id] = revision.parent_of(champ.type_de_champ)
    end

    added_champs = diff[:added].filter { _1.persisted? && _1.fillable? }
    updated_champs = diff[:updated].filter { _1.persisted? && _1.fillable? }

    added_champs.each { _1.update_column(:dossier_id, id) }

    if updated_champs.present?
      champs_index = champs.index_by(&:public_id)
      updated_champs.each do |champ|
        champs_index[champ.public_id]&.destroy!
        champ.update_column(:dossier_id, id)
      end
    end

    added_row_ids.each do |row_id, repetition_type_de_champ|
      champ_for_update(repetition_type_de_champ, row_id:, updated_by: user.email).save!
    end
    removed_row_ids.each do |row_id, repetition_type_de_champ|
      champ_for_update(repetition_type_de_champ, row_id:, updated_by: user.email).discard!
    end
  end
end
