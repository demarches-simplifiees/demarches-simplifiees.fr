# frozen_string_literal: true

module DossierRebaseConcern
  extend ActiveSupport::Concern

  def rebase!(force: false)
    ProcedureRevisionPreloader.new([procedure.published_revision, revision].compact).all
    return if procedure.published_revision.blank?

    if force || can_rebase?
      transaction do
        rebase
      end
    end
  end

  def rebase_later
    DossierRebaseJob.perform_later(self)
  end

  def can_rebase?
    procedure.published_revision.present? && revision != procedure.published_revision &&
      (brouillon? || accepted_en_construction_changes? || accepted_en_instruction_changes?)
  end

  def pending_changes
    procedure.published_revision.present? ? revision.compare_types_de_champ(procedure.published_revision) : []
  end

  def can_rebase_mandatory_change?(stable_id)
    !champs.filter { _1.stable_id == stable_id }.any?(&:blank?)
  end

  def can_rebase_drop_down_options_change?(stable_id, options)
    !champs.filter { _1.stable_id == stable_id }.any? { _1.in?(options) }
  end

  private

  def accepted_en_construction_changes?
    en_construction? && pending_changes.all? { _1.can_rebase?(self) }
  end

  def accepted_en_instruction_changes?
    en_instruction? && pending_changes.all? { _1.can_rebase?(self) }
  end

  def rebase
    # revision we are rebasing to
    target_revision = procedure.published_revision

    changed_stable_ids_by_op = pending_changes
      .group_by(&:op)
      .transform_values { _1.map(&:stable_id) }
    updated_stable_ids = changed_stable_ids_by_op.fetch(:update, [])
    added_stable_ids = changed_stable_ids_by_op.fetch(:add, [])

    # update dossier revision
    update_column(:revision_id, target_revision.id)

    # mark updated champs as rebased
    champs.where(stable_id: updated_stable_ids).update_all(rebased_at: Time.zone.now)

    # add rows for new repetitions
    repetition_types_de_champ = target_revision
      .types_de_champ
      .repetition
      .where(stable_id: added_stable_ids)
    repetition_types_de_champ.mandatory
      .or(repetition_types_de_champ.private_only)
      .find_each do |type_de_champ|
        self.champs << type_de_champ.build_champ(row_id: ULID.generate, rebased_at: Time.zone.now)
      end
  end
end
