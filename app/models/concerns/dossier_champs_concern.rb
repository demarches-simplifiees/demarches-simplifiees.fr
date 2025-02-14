# frozen_string_literal: true

module DossierChampsConcern
  extend ActiveSupport::Concern

  def project_champ(type_de_champ, row_id: nil)
    check_valid_row_id_on_read?(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if champ.nil? || !champ.is_type?(type_de_champ.type_champ)
      value = type_de_champ.champ_blank?(champ) ? nil : champ.value
      updated_at = champ&.updated_at || depose_at || created_at
      rebased_at = champ&.rebased_at
      type_de_champ.build_champ(dossier: self, row_id:, updated_at:, rebased_at:, value:)
    else
      champ
    end
  end

  def project_champs_public
    @project_champs_public ||= revision.types_de_champ_public.map { project_champ(_1) }
  end

  def project_champs_private
    @project_champs_private ||= revision.types_de_champ_private.map { project_champ(_1) }
  end

  def filled_champs_public
    @filled_champs_public ||= project_champs_public.flat_map do |champ|
      if champ.repetition?
        champ.rows.flatten.filter { _1.persisted? && _1.fillable? }
      elsif champ.persisted? && champ.fillable?
        champ
      else
        []
      end
    end
  end

  def filled_champs_private
    @filled_champs_private ||= project_champs_private.flat_map do |champ|
      if champ.repetition?
        champ.rows.flatten.filter { _1.persisted? && _1.fillable? }
      elsif champ.persisted? && champ.fillable?
        champ
      else
        []
      end
    end
  end

  def filled_champs
    filled_champs_public + filled_champs_private
  end

  def project_champs_public_all
    revision.types_de_champ_public.flat_map do |type_de_champ|
      champ = project_champ(type_de_champ)
      if type_de_champ.repetition?
        [champ] + project_rows_for(type_de_champ).flatten
      else
        champ
      end
    end
  end

  def project_champs_private_all
    revision.types_de_champ_private.flat_map do |type_de_champ|
      champ = project_champ(type_de_champ)
      if type_de_champ.repetition?
        [champ] + project_rows_for(type_de_champ).flatten
      else
        champ
      end
    end
  end

  def project_rows_for(type_de_champ)
    return [] if !type_de_champ.repetition?

    children = revision.children_of(type_de_champ)
    row_ids = repetition_row_ids(type_de_champ)

    row_ids.map do |row_id|
      children.map { project_champ(_1, row_id:) }
    end
  end

  def find_type_de_champ_by_stable_id(stable_id, scope = nil)
    case scope
    when :public
      revision.types_de_champ.public_only
    when :private
      revision.types_de_champ.private_only
    else
      revision.types_de_champ
    end.find_by!(stable_id:)
  end

  def champs_for_prefill(stable_ids)
    revision
      .types_de_champ
      .filter { _1.stable_id.in?(stable_ids) }
      .filter { !_1.child?(revision) }
      .map { _1.repetition? ? project_champ(_1) : champ_for_update(_1, updated_by: nil) }
  end

  def champ_value_for_tag(type_de_champ, path = :value)
    champ = if type_de_champ.repetition?
      project_champ(type_de_champ)
    else
      filled_champ(type_de_champ)
    end
    type_de_champ.champ_value_for_tag(champ, path)
  end

  def champ_for_update(type_de_champ, row_id: nil, updated_by:)
    champ = champ_upsert_by!(type_de_champ, row_id)
    champ.updated_by = updated_by
    champ
  end

  def update_champs_attributes(attributes, scope, updated_by:)
    champs_attributes = attributes.to_h.map do |public_id, attributes|
      champ_attributes_by_public_id(public_id, attributes, scope, updated_by:)
    end

    assign_attributes(champs_attributes:)
  end

  def repetition_rows_for_export(type_de_champ)
    repetition_row_ids(type_de_champ).map.with_index(1) do |row_id, index|
      Champs::RepetitionChamp::Row.new(index:, row_id:, dossier: self)
    end
  end

  def repetition_row_ids(type_de_champ)
    return [] if !type_de_champ.repetition?
    return [] unless stable_id_in_revision?(type_de_champ.stable_id)
    @repetition_row_ids ||= {}
    @repetition_row_ids[type_de_champ.stable_id] ||= begin
      rows = champs_in_revision.filter { _1.row? && _1.stable_id == type_de_champ.stable_id }
      row_ids = rows.reject(&:discarded?).map(&:row_id)

      # Legacy rows are rows that have been created before the introduction of the discarded_at column
      # TODO migrate and clean
      children_stable_ids = revision.children_of(type_de_champ).map(&:stable_id)
      discarded_row_ids = rows.filter(&:discarded?).map(&:row_id)
      legacy_row_ids = champs_in_revision.filter { _1.stable_id.in?(children_stable_ids) && _1.row_id.present? }.map(&:row_id).uniq
      row_ids += (legacy_row_ids - discarded_row_ids)
      row_ids.uniq.sort
    end
  end

  def repetition_add_row(type_de_champ, updated_by:)
    raise "Can't add row to non-repetition type de champ" if !type_de_champ.repetition?

    row_id = ULID.generate
    champ_for_update(type_de_champ, row_id:, updated_by:)
    row_id
  end

  def repetition_remove_row(type_de_champ, row_id, updated_by:)
    raise "Can't remove row from non-repetition type de champ" if !type_de_champ.repetition?

    champ = champ_for_update(type_de_champ, row_id:, updated_by:)
    champ.discard!
  end

  def stable_id_in_revision?(stable_id)
    revision_stable_ids.member?(stable_id.to_i)
  end

  def reload
    super.tap { reset_champs_cache }
  end

  private

  def champs_by_public_id
    @champs_by_public_id ||= champs_in_revision.index_by(&:public_id)
  end

  def revision_stable_ids
    @revision_stable_ids ||= revision.types_de_champ.map(&:stable_id).to_set
  end

  def champs_in_revision
    champs.filter { stable_id_in_revision?(_1.stable_id) }
  end

  def filled_champ(type_de_champ, row_id: nil)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if type_de_champ.champ_blank?(champ) || !champ.visible?
      nil
    else
      champ
    end
  end

  def champ_attributes_by_public_id(public_id, attributes, scope, updated_by:)
    stable_id, row_id = public_id.split('-')
    type_de_champ = find_type_de_champ_by_stable_id(stable_id, scope)
    champ = champ_upsert_by!(type_de_champ, row_id)
    attributes.merge(id: champ.id, updated_by:)
  end

  def champ_upsert_by!(type_de_champ, row_id)
    check_valid_row_id_on_write?(type_de_champ, row_id)

    champ = Dossier.no_touching do
      champs
        .create_with(**type_de_champ.params_for_champ)
        .create_or_find_by!(stable_id: type_de_champ.stable_id, row_id: row_id || Champ::NULL_ROW_ID, stream: 'main')
    end

    # Needed when a revision change the champ type in this case, we reset the champ data
    if !champ.is_a?(type_de_champ.champ_class)
      champ = champ.becomes!(type_de_champ.champ_class)
      champ.assign_attributes(value: nil, value_json: nil, external_id: nil, data: nil)
    end

    # If the champ returned from `create_or_find_by` is not the same as the one already loaded in `dossier.champs`, we need to update the association cache
    loaded_champ = champs.find { [_1.stream, _1.public_id] == [champ.stream, champ.public_id] }
    if loaded_champ.present? && loaded_champ.object_id != champ.object_id
      association(:champs).target = champs - [loaded_champ] + [champ]
    end

    # If the dossier instance on champ has changed we need to update the association cache
    if champ.dossier.object_id != object_id
      champ.association(:dossier).target = self
    end

    reset_champs_cache

    champ.save!
    champ
  end

  def check_valid_row_id_on_write?(type_de_champ, row_id)
    if type_de_champ.repetition?
      if row_id.blank?
        raise "type_de_champ #{type_de_champ.stable_id} in revision #{revision_id} must have a row_id because it represents a row in a repetition"
      end
    else
      check_valid_row_id_on_read?(type_de_champ, row_id)
    end
  end

  def check_valid_row_id_on_read?(type_de_champ, row_id)
    if type_de_champ.child?(revision)
      if row_id.blank?
        raise "type_de_champ #{type_de_champ.stable_id} in revision #{revision_id} must have a row_id because it is part of a repetition"
      end
    elsif row_id.present? && stable_id_in_revision?(type_de_champ.stable_id)
      raise "type_de_champ #{type_de_champ.stable_id} in revision #{revision_id} can not have a row_id because it is not part of a repetition"
    end
  end

  def reset_champs_cache
    @champs_by_public_id = nil
    @filled_champs_public = nil
    @filled_champs_private = nil
    @project_champs_public = nil
    @project_champs_private = nil
    @repetition_row_ids = nil
    @revision_stable_ids = nil
  end
end
