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
    changes_by_type_de_champ = pending_changes
      .filter { |change| change[:model] == :type_de_champ }
      .group_by { |change| change[:stable_id] }

    changes_by_type_de_champ.each do |stable_id, changes|
      type_de_champ = find_type_de_champ_by_stable_id(stable_id)
      published_type_de_champ = find_type_de_champ_by_stable_id(stable_id, published: true)

      changes.each do |change|
        case change[:op]
        when :add
          add_new_champs_for_revision(published_type_de_champ)
        when :remove
          delete_champs_for_revision(type_de_champ)
        end
      end
    end

    flattened_all_champs.each do |champ|
      changes_by_stable_id = (changes_by_type_de_champ[champ.stable_id] || [])
        .filter { |change| change[:op] == :update }

      update_champ_for_revision(champ) do |update|
        changes_by_stable_id.each do |change|
          case change[:attribute]
          when :type_champ
            update[:type] = "Champs::#{change[:to].classify}Champ"
            update[:value] = nil
            update[:external_id] = nil
            update[:data] = nil
            geo_areas_to_delete += champ.geo_areas
            if champ.piece_justificative_file.attached?
              attachments_to_purge << champ.piece_justificative_file
            end
          when :drop_down_options
            update[:value] = nil
          when :carte_layers
            if change[:from].include?(:cadastres) && !change[:to].include?(:cadastres)
              geo_areas_to_delete += champ.cadastres
            end
          end
          update[:rebased_at] = Time.zone.now
        end
      end
    end

    self.update_column(:revision_id, procedure.published_revision_id)
    attachments_to_purge.each(&:purge_later)
    geo_areas_to_delete.each(&:destroy)
  end

  def add_new_champs_for_revision(published_type_de_champ)
    if published_type_de_champ.parent
      find_champs_by_stable_id(published_type_de_champ.parent.stable_id).each do |champ_repetition|
        champ_repetition.champs.map(&:row).uniq.each do |row|
          champ = published_type_de_champ.champ.build(row: row)
          champ_repetition.champs << champ
        end
      end
    else
      champ = published_type_de_champ.build_champ(revision: procedure.published_revision)
      self.champs << champ
    end
  end

  def update_champ_for_revision(champ)
    published_type_de_champ = find_type_de_champ_by_stable_id(champ.stable_id, published: true)
    return if !published_type_de_champ

    update = {}

    yield update

    if champ.type_de_champ != published_type_de_champ
      update[:type_de_champ_id] = published_type_de_champ.id
    end

    if update.present?
      champ.update_columns(update)
    end
  end

  def delete_champs_for_revision(published_type_de_champ)
    Champ.where(id: find_champs_by_stable_id(published_type_de_champ.stable_id).map(&:id))
      .destroy_all
  end

  def flattened_all_types_de_champ(published: false)
    revision = published ? procedure.published_revision : self.revision
    types_de_champ = revision.types_de_champ_public + revision.types_de_champ_private
    (types_de_champ + types_de_champ.filter(&:repetition?).flat_map(&:types_de_champ))
      .index_by(&:stable_id)
  end

  def flattened_all_champs
    all_champs = (champs + champs_private)
    all_champs + all_champs.filter(&:repetition?).flat_map(&:champs)
  end

  def find_type_de_champ_by_stable_id(stable_id, published: false)
    flattened_all_types_de_champ(published: published)[stable_id]
  end

  def find_champs_by_stable_id(stable_id)
    flattened_all_champs.filter do |champ|
      champ.stable_id == stable_id
    end
  end
end
