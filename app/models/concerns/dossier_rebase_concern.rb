module DossierRebaseConcern
  extend ActiveSupport::Concern

  def rebase!
    if can_rebase?
      transaction do
        rebase
      end
    end
  end

  def rebase_later
    DossierRebaseJob.perform_later(self)
  end

  def can_rebase?
    revision != procedure.published_revision &&
      (brouillon? || accepted_en_construction_changes? || accepted_en_instruction_changes?)
  end

  def pending_changes
    revision.compare(procedure.published_revision)
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
      .includes(:type_de_champ, :parent)
      .index_by(&:stable_id)

    changes_by_op = pending_changes
      .group_by(&:op)
      .tap { _1.default = [] }

    # add champ
    changes_by_op[:add]
      .map(&:stable_id)
      .map { target_coordinates_by_stable_id[_1] }
      .each { add_new_champs_for_revision(_1) }

    # remove champ
    changes_by_op[:remove]
      .each { delete_champs_for_revision(_1.stable_id) }

    if brouillon?
      changes_by_op[:update]
        .map { |change| [change, champs.joins(:type_de_champ).where(type_de_champ: { stable_id: change.stable_id })] }
        .each { |change, champs| apply(change, champs) }
    end

    # due to repetition tdc clone on update or erase
    # we must reassign tdc to the latest version
    Champ
      .includes(:type_de_champ)
      .where(dossier: self)
      .map { [_1, target_coordinates_by_stable_id[_1.stable_id].type_de_champ] }
      .each { |champ, target_tdc| champ.update_columns(type_de_champ_id: target_tdc.id, rebased_at: Time.zone.now) }

    # update dossier revision
    self.update_column(:revision_id, target_revision.id)
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
        data: nil)
    when :drop_down_options
      # we are removing options, we need to remove the value if it contains one of the removed options
      removed_options = change.from - change.to
      if removed_options.present? && champs.any? { _1.in?(removed_options) }
        champs.filter { _1.in?(removed_options) }.each { _1.remove_option(removed_options) }
      end
    when :carte_layers
      # if we are removing cadastres layer, we need to remove cadastre geo areas
      if change.from.include?(:cadastres) && !change.to.include?(:cadastres)
        champs.each { _1.cadastres.each(&:destroy) }
      end
    end
  end

  def add_new_champs_for_revision(target_coordinate)
    if target_coordinate.child?
      # If this type de champ is a child, we create a new champ for each row of the parent
      parent_stable_id = target_coordinate.parent.stable_id
      champs_repetition = champs
        .includes(:champs, :type_de_champ)
        .where(type_de_champ: { stable_id: parent_stable_id })

      champs_repetition.each do |champ_repetition|
        champ_repetition.champs.index_by(&:row).each do |(row, champ)|
          create_champ(target_coordinate, champ_repetition, row:, row_id: champ.row_id)
        end
      end
    else
      create_champ(target_coordinate, self)
    end
  end

  def create_champ(target_coordinate, parent, row: nil, row_id: nil)
    params = { revision: target_coordinate.revision, row:, row_id: }.compact
    champ = target_coordinate
      .type_de_champ
      .build_champ(params)
    parent.champs << champ
  end

  def delete_champs_for_revision(stable_id)
    champs
      .joins(:type_de_champ)
      .where(types_de_champ: { stable_id: })
      .destroy_all
  end

  def purge_piece_justificative_file(champ)
    ActiveStorage::Attachment.where(id: champ.piece_justificative_file.ids).delete_all
  end
end
