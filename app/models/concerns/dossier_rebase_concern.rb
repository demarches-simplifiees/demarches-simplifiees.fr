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

    # index published types de champ coordinates by stable_id
    target_coordinates_by_stable_id = target_revision
      .revision_types_de_champ
      .includes(:parent)
      .index_by(&:stable_id)

    changes_by_op = pending_changes
      .group_by(&:op)
      .tap { _1.default = [] }

    champs_by_stable_id = champs
      .group_by(&:stable_id)
      .transform_values { Champ.where(id: _1) }
      .tap { _1.default = Champ.none }

    # remove champ
    changes_by_op[:remove].each { champs_by_stable_id[_1.stable_id].destroy_all }

    # update champ
    changes_by_op[:update].each { champs_by_stable_id[_1.stable_id].update_all(rebased_at: Time.zone.now) }

    # update dossier revision
    update_column(:revision_id, target_revision.id)

    # add champ (after changing dossier revision to avoid errors)
    changes_by_op[:add]
      .map { target_coordinates_by_stable_id[_1.stable_id] }
      .each { add_new_champs_for_revision(_1) }
  end

  def add_new_champs_for_revision(target_coordinate)
    if target_coordinate.child?
      row_ids = repetition_row_ids(target_coordinate.parent.type_de_champ)

      if row_ids.present?
        row_ids.each do |row_id|
          create_champ(target_coordinate, row_id:)
        end
      elsif target_coordinate.parent.mandatory?
        create_champ(target_coordinate, row_id: ULID.generate)
      end
    else
      create_champ(target_coordinate)
    end
  end

  def create_champ(target_coordinate, row_id: nil)
    self.champs << target_coordinate
      .type_de_champ
      .build_champ(rebased_at: Time.zone.now, row_id:)
  end

  def purge_piece_justificative_file(champ)
    ActiveStorage::Attachment.where(id: champ.piece_justificative_file.ids).delete_all
  end
end
