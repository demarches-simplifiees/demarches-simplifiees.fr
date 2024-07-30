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

    # update champ
    changes_by_op[:update].each { apply(_1, champs_by_stable_id[_1.stable_id]) }

    # update dossier revision
    update_column(:revision_id, target_revision.id)

    # add repetition champs rows
    changes_by_op[:add]
      .map { target_coordinates_by_stable_id[_1.stable_id] }
      .map(&:type_de_champ)
      .filter { _1.repetition? && (_1.mandatory? || _1.private?) }
      .each { add_repetition_row_for_revision(_1) }
  end

  def apply(change, champs)
    case change.attribute
    when :type_champ
      champs.each { purge_piece_justificative_file(_1) }
      GeoArea.where(champ: champs).destroy_all
      Etablissement.where(champ: champs).destroy_all
      champs.update_all(type: "Champs::#{change.to.classify}Champ",
        value: nil,
        value_json: nil,
        external_id: nil,
        data: nil,
        rebased_at: Time.zone.now)
    when :drop_down_options
      # we are removing options, we need to remove the value if it contains one of the removed options
      removed_options = change.from - change.to
      if removed_options.present? && champs.any? { _1.in?(removed_options) }
        champs.filter { _1.in?(removed_options) }.each do
          _1.remove_option(removed_options)
          _1.update_column(:rebased_at, Time.zone.now)
        end
      end
    when :carte_layers
      # if we are removing cadastres layer, we need to remove cadastre geo areas
      if change.from.include?(:cadastres) && !change.to.include?(:cadastres)
        champs.filter { _1.cadastres.present? }.each do
          _1.cadastres.each(&:destroy)
          _1.update_column(:rebased_at, Time.zone.now)
        end
      end
    else
      champs.update_all(rebased_at: Time.zone.now)
    end
  end

  def add_repetition_row_for_revision(type_de_champ)
    champ = type_de_champ.build_champ(dossier: self, row_id: ULID.generate)
    champ.save!
  end

  def purge_piece_justificative_file(champ)
    ActiveStorage::Attachment.where(id: champ.piece_justificative_file.ids).delete_all
  end
end
