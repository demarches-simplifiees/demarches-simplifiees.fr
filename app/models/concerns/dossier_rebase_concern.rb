module DossierRebaseConcern
  extend ActiveSupport::Concern

  def rebase!
    if can_rebase?
      transaction do
        rebase
      end
    end
  end

  def can_rebase?
    revision != procedure.published_revision &&
      (brouillon? || accepted_en_construction_changes? || accepted_en_instruction_changes?)
  end

  def pending_changes
    revision.compare(procedure.published_revision)
  end

  private

  def accepted_en_construction_changes?
    en_construction? && pending_changes.all? { |change| accepted_en_construction_change?(change) }
  end

  def accepted_en_instruction_changes?
    en_instruction? && pending_changes.all? { |change| accepted_en_instruction_change?(change) }
  end

  def accepted_en_construction_change?(change)
    if change[:model] == :attestation_template || change[:op] == :move || change[:op] == :remove
      true
    elsif change[:op] == :update
      case change[:attribute]
      when :carte_layers
        true
      when :mandatory
        change[:from] && !change[:to]
      else
        false
      end
    else
      false
    end
  end

  def accepted_en_instruction_change?(change)
    change[:model] == :attestation_template
  end

  def rebase
    attachments_to_purge = []
    geo_areas_to_delete = []
    champs_to_delete = []

    # revision we are rebasing to
    target_revision = procedure.published_revision

    # group changes by stable_id
    # { 12 : [ move, update_libelle, update_mandatory ]
    changes_by_stable_id = pending_changes
      .filter { |change| change[:model] == :type_de_champ }
      .group_by { |change| change[:stable_id] }

    # index current revision types de champ by stable_id
    current_types_de_champ_by_stable_id = revision.types_de_champ.index_by(&:stable_id)

    # index published types de champ coordinates by stable_id
    target_coordinates_by_stable_id = target_revision
      .revision_types_de_champ
      .includes(:type_de_champ, :parent)
      .index_by(&:stable_id)

    # add and remove champs
    changes_by_stable_id.each do |stable_id, changes|
      type_de_champ = current_types_de_champ_by_stable_id[stable_id]
      published_coordinate = target_coordinates_by_stable_id[stable_id]

      changes.each do |change|
        case change[:op]
        when :add
          add_new_champs_for_revision(published_coordinate)
        when :remove
          delete_champs_for_revision(type_de_champ)
        end
      end
    end

    # find all champs with respective update changes and the published type de champ
    champs_with_changes = Champ.where(dossier: self).includes(:type_de_champ).filter_map do |champ|
      # type de champ from published revision
      type_de_champ = target_coordinates_by_stable_id[champ.stable_id]&.type_de_champ
      # only update op changes
      changes = (changes_by_stable_id[champ.stable_id] || []).filter { |change| change[:op] == :update }

      if type_de_champ
        [champ, type_de_champ, changes]
      end
    end

    # apply changes to existing champs and reset values when needed
    update_champs_for_revision(champs_with_changes) do |champ, change, update|
      case change[:attribute]
      when :type_champ
        update[:type] = "Champs::#{change[:to].classify}Champ"
        update[:value] = nil
        update[:external_id] = nil
        update[:data] = nil
        geo_areas_to_delete += champ.geo_areas
        champs_to_delete += champ.champs
        if champ.piece_justificative_file.attached?
          attachments_to_purge << champ.piece_justificative_file
        end
      when :drop_down_options
        update[:value] = nil
      when :carte_layers
        # if we are removing cadastres layer, we need to remove cadastre geo areas
        if change[:from].include?(:cadastres) && !change[:to].include?(:cadastres)
          geo_areas_to_delete += champ.cadastres
        end
      end
      update[:rebased_at] = Time.zone.now
    end

    # update dossier revision
    self.update_column(:revision_id, target_revision.id)

    # clear orphaned data
    attachments_to_purge.each(&:purge_later)
    geo_areas_to_delete.each(&:destroy)
    champs_to_delete.each(&:destroy)
  end

  def add_new_champs_for_revision(published_coordinate)
    if published_coordinate.child?
      # If this type de champ is a child, we create a new champ for each row of the parent
      parent_stable_id = published_coordinate.parent.stable_id
      champs_repetition = Champ
        .includes(:champs, :type_de_champ)
        .where(dossier: self, type_de_champ: { stable_id: parent_stable_id })

      champs_repetition.each do |champ_repetition|
        champ_repetition.champs.map(&:row).uniq.each do |row|
          create_champ(published_coordinate, champ_repetition, row: row)
        end
      end
    else
      create_champ(published_coordinate, self)
    end
  end

  def create_champ(published_coordinate, parent, row: nil)
    params = { revision: published_coordinate.revision }
    params[:row] = row if row
    champ = published_coordinate
      .type_de_champ
      .build_champ(params)
    parent.champs << champ
  end

  def update_champs_for_revision(champs_with_changes)
    champs_with_changes.each do |champ, type_de_champ, changes|
      update = {}

      changes.each do |change|
        yield champ, change, update
      end

      # update type de champ to reflect new revision
      if champ.type_de_champ != type_de_champ
        update[:type_de_champ_id] = type_de_champ.id
      end

      if update.present?
        champ.update_columns(update)
      end
    end
  end

  def delete_champs_for_revision(type_de_champ)
    Champ
      .where(dossier: self, type_de_champ: type_de_champ)
      .destroy_all
  end
end
