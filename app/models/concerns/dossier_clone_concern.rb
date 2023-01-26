module DossierCloneConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :parent_dossier, class_name: 'Dossier', optional: true
    has_many :cloned_dossiers, class_name: 'Dossier', foreign_key: :parent_dossier_id, dependent: :nullify, inverse_of: :parent_dossier

    belongs_to :editing_fork_origin, class_name: 'Dossier', optional: true
    has_many :editing_forks, class_name: 'Dossier', foreign_key: :editing_fork_origin_id, dependent: :destroy, inverse_of: :editing_fork_origin
  end

  def find_or_create_editing_fork(user, editing_fork_scope)
    find_editing_fork(user, editing_fork_scope) || clone(user:, editing_fork_scope: editing_fork_scope.to_sym)
  end

  def find_editing_fork(user, editing_fork_scope)
    editing_fork = editing_forks.find_by(user:, editing_fork_scope:)
    editing_fork.rebase! if editing_fork.present?
    editing_fork
  end

  def reset_editing_fork!
    if editing_fork? && (forked_with_changes? || editing_fork_origin.updated_at > updated_at)
      destroy_editing_fork!
    end
  end

  def destroy_editing_fork!
    if editing_fork?
      update_column(:editing_fork_scope, :discarded)
      DestroyRecordLaterJob.perform_later(self)
    end
  end

  def editing_fork?
    editing_fork_origin_id.present?
  end

  def make_diff(editing_fork)
    champs_to_diff = case editing_fork.editing_fork_scope.to_sym
    when :public
      champs_public_all
    when :private
      champs_private_all
    else
      raise "dossier #{editing_fork.id} is not a fork"
    end

    origin_updated_at = champs_to_diff.map(&:updated_at).max
    origin_champs_index = champs_to_diff.index_by(&:stable_id_with_row)
    forked_champs_index = editing_fork.champs.index_by(&:stable_id_with_row)
    updated_champs_index = editing_fork
      .champs
      .filter { _1.updated_at > origin_updated_at }
      .index_by(&:stable_id_with_row)

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
    diff = make_diff(editing_fork)
    transaction do
      apply_diff(diff)
      update_column(:revision_id, editing_fork.revision_id)
      editing_fork.destroy_editing_fork!
      reload
    end
  end

  def clone(editing_fork_scope: nil, user: nil)
    dossier_attributes = [:autorisation_donnees, :revision_id, :groupe_instructeur_id]
    relationships = [:individual, :etablissement]

    champs_to_clone = case editing_fork_scope
    when :private
      champs_private_all
    when :public
      champs_public_all
    else
      champs
    end

    cloned_champs = champs_to_clone
      .index_by(&:id)
      .transform_values { [_1, _1.clone(editing_fork_scope.present?)] }

    cloned_dossier = deep_clone(only: dossier_attributes, include: relationships) do |original, kopy|
      PiecesJustificativesService.clone_attachments(original, kopy)

      if original.is_a?(Dossier)
        if editing_fork_scope.present?
          kopy.editing_fork_origin = original
          kopy.editing_fork_scope = editing_fork_scope
        else
          kopy.parent_dossier = original
        end

        kopy.user = user || original.user
        kopy.state = Dossier.states.fetch(:brouillon)

        kopy.champs = cloned_champs.values.map do |(_, champ)|
          champ.dossier = kopy
          champ.parent = cloned_champs[champ.parent_id].second if champ.child?
          champ
        end
      end
    end

    transaction do
      cloned_dossier.save!

      if editing_fork_scope.present?
        cloned_champs.values.each do |(original, champ)|
          champ.update_columns(created_at: original.created_at, updated_at: original.updated_at)
        end
        cloned_dossier.rebase!
      end
    end

    cloned_dossier.reload
  end

  def forked_with_changes?
    if forked_diff.present?
      forked_diff.values.any?(&:present?)
    end
  end

  def champ_forked_with_changes?(champ)
    if forked_diff.present?
      forked_diff.values.any? { _1.include?(champ) }
    end
  end

  private

  def forked_diff
    @forked_diff ||= editing_fork? ? editing_fork_origin.make_diff(self) : nil
  end

  def apply_diff(diff)
    champs_index = (champs + diff[:added]).index_by(&:stable_id_with_row)

    diff[:added].each do |champ|
      if champ.child?
        champ.update_columns(dossier_id: id, parent: champs_index[champ.parent.stable_id_with_row])
      else
        champ.update_column(:dossier_id, id)
      end
    end

    champs_to_remove = []
    diff[:updated].each do |champ|
      champs_to_remove << champs_index[champ.stable_id_with_row]
      if champ.child?
        champ.update_columns(dossier_id: id, parent: champs_index[champ.parent.stable_id_with_row])
      else
        champ.update_column(:dossier_id, id)
      end
    end

    champs_to_remove += diff[:removed]
    champs_to_remove
      .filter { !_1.child? || !champs_to_remove.include?(_1.parent) }
      .each(&:destroy)
  end
end
