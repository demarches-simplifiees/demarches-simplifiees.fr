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
      published_revision_type_de_champ = find_published_revision_types_de_champ_by_stable_id(stable_id)

      changes.each do |change|
        case change[:op]
        when :add
          add_new_champs_for_revision(published_revision_type_de_champ)
        when :remove
          delete_champs_for_revision(type_de_champ)
        end
      end
    end

    champs_all.each do |champ|
      changes_by_stable_id = (changes_by_type_de_champ[champ.stable_id] || [])
        .filter { |change| change[:op] == :update }
      published_revision_type_de_champ = find_published_revision_types_de_champ_by_stable_id(champ.stable_id)

      update_champ_for_revision(champ, published_revision_type_de_champ&.type_de_champ) do |update|
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

  def add_new_champs_for_revision(revision_type_de_champ)
    published_type_de_champ = revision_type_de_champ.type_de_champ
    if revision_type_de_champ.child?
      find_champs_by_stable_id(revision_type_de_champ.parent.stable_id).each do |champ_repetition|
        champ_repetition.champs << champ_repetition.champs.map(&:row).uniq.map do |row|
          published_type_de_champ.build_champ(row: row)
        end
      end
    else
      self.champs << published_type_de_champ.build_champ(dossier: self)
    end
  end

  def update_champ_for_revision(champ, published_type_de_champ)
    return if !published_type_de_champ

    update = {}

    yield update

    if champ.type_de_champ_id != published_type_de_champ.id
      update[:type_de_champ_id] = published_type_de_champ.id
    end

    if update.present?
      champ.update_columns(update)
    end
  end

  def delete_champs_for_revision(published_type_de_champ)
    Champ.where(id: find_champs_by_stable_id(published_type_de_champ.stable_id))
      .destroy_all
  end

  def find_type_de_champ_by_stable_id(stable_id)
    all_types_de_champ_by_stable_id[stable_id]
  end

  def find_published_revision_types_de_champ_by_stable_id(stable_id)
    all_published_revision_types_de_champ_by_stable_id[stable_id]
  end

  def find_champs_by_stable_id(stable_id)
    all_champs_by_stable_id[stable_id]
  end

  def all_champs_by_stable_id
    @all_champs_by_stable_id ||= champs_all.group_by(&:stable_id)
  end

  def all_published_revision_types_de_champ_by_stable_id
    @all_published_revision_types_de_champ_by_stable_id ||= procedure.published_revision
      .revision_types_de_champ_all
      .index_by(&:stable_id)
  end

  def all_types_de_champ_by_stable_id
    @all_types_de_champ_by_stable_id ||= revision
      .types_de_champ_all
      .index_by(&:stable_id)
  end
end
