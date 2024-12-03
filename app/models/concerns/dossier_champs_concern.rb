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
      rows = champs_on_stream.filter { _1.row? && _1.stable_id == type_de_champ.stable_id }
      row_ids = rows.reject(&:discarded?).map(&:row_id)

      # Legacy rows are rows that have been created before the introduction of the discarded_at column
      # TODO migrate and clean
      children_stable_ids = revision.children_of(type_de_champ).map(&:stable_id)
      discarded_row_ids = rows.filter(&:discarded?).map(&:row_id)
      legacy_row_ids = champs_on_stream.filter { _1.stable_id.in?(children_stable_ids) && _1.row_id.present? }.map(&:row_id).uniq
      row_ids += (legacy_row_ids - discarded_row_ids)
      row_ids.uniq.sort
    end
  end

  def repetition_add_row(type_de_champ, updated_by:)
    raise "Can't add row to non-repetition type de champ" if !type_de_champ.repetition?

    row_id = ULID.generate
    champ = champ_for_update(type_de_champ, row_id:, updated_by:)
    champ.save!
    reset_champ_cache(champ)
    row_id
  end

  def repetition_remove_row(type_de_champ, row_id, updated_by:)
    raise "Can't remove row from non-repetition type de champ" if !type_de_champ.repetition?

    champ = champ_for_update(type_de_champ, row_id:, updated_by:)
    champ.discard!
    reset_champ_cache(champ)
  end

  def stable_id_in_revision?(stable_id)
    revision_stable_ids.member?(stable_id.to_i)
  end

  def reload
    super.tap { reset_champs_cache }
  end

  def merge_stream(stream)
    case stream
    when Champ::USER_DRAFT_STREAM
      merge_user_draft_stream
    else
      raise ArgumentError, "Invalid stream: #{stream}"
    end

    reload_champs_cache
  end

  def reset_stream(stream)
    case stream
    when Champ::USER_DRAFT_STREAM
      champs.where(stream:).delete_all
    else
      raise ArgumentError, "Invalid stream: #{stream}"
    end

    reload_champs_cache
  end

  def user_draft_changes?
    # TODO remove when all forks are gone
    return true if forked_with_changes?

    champs_on_user_draft_stream.present?
  end

  def user_draft_changes_on_champ?(champ)
    # TODO remove when all forks are gone
    return true if champ_forked_with_changes?(champ)

    champs_on_user_draft_stream.any? { _1.public_id == champ.public_id }
  end

  def with_stream(stream)
    if block_given?
      previous_stream = @stream
      @stream = stream
      reset_champs_cache
      result = yield
      @stream = previous_stream
      reset_champs_cache
      result
    else
      @stream = stream
      reset_champs_cache
      self
    end
  end

  def stream
    @stream || Champ::MAIN_STREAM
  end

  def history
    champs_in_revision.filter(&:history_stream?)
  end

  private

  def merge_user_draft_stream
    draft_champs = champs.where(stream: Champ::USER_DRAFT_STREAM, stable_id: revision_stable_ids)
      .pluck(:id, :stable_id, :row_id)
      .index_by { |(_, stable_id, row_id)| [stable_id, row_id].compact }
      .transform_values(&:first)

    return if draft_champs.empty?

    main_champs = champs.where(stream: Champ::MAIN_STREAM, stable_id: revision_stable_ids)
      .pluck(:id, :stable_id, :row_id)
      .index_by { |(_, stable_id, row_id)| [stable_id, row_id].compact }
      .transform_values(&:first)

    draft_champ_ids = draft_champs.values
    main_champ_ids = main_champs.filter_map { |key, id| id if draft_champs.key?(key) }

    now = Time.zone.now
    transaction do
      champs.where(id: main_champ_ids, stream: Champ::MAIN_STREAM).update_all(stream: "#{Champ::HISTORY_STREAM}#{now}")
      champs.where(id: draft_champ_ids, stream: Champ::USER_DRAFT_STREAM).update_all(stream: Champ::MAIN_STREAM, updated_at: now)
    end

    update(last_champ_updated_at: now)
    if Champ.exists?(id: draft_champ_ids, type: ['Champs::PieceJustificativeChamp', 'Champs::TitreIdentiteChamp'])
      update(last_champ_piece_jointe_updated_at: now)
    end

    reload_champs_cache
  end

  def champs_by_public_id
    @champs_by_public_id ||= champs_on_stream.index_by(&:public_id)
  end

  def champs_on_stream
    @champs_on_stream ||= case stream
    when Champ::USER_DRAFT_STREAM
      (champs_on_user_draft_stream + champs_on_main_stream).uniq(&:public_id)
    else
      champs_on_main_stream
    end
  end

  def revision_stable_ids
    @revision_stable_ids ||= revision.types_de_champ.map(&:stable_id).to_set
  end

  def champs_in_revision
    champs.filter { stable_id_in_revision?(_1.stable_id) }
  end

  def champs_on_main_stream
    champs_in_revision.filter(&:main_stream?)
  end

  def champs_on_user_draft_stream
    champs_in_revision.filter(&:user_draft_stream?)
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
    champ_attributes = type_de_champ.params_for_champ
    # TODO: Once we have the right index in place, we should change this to use `create_or_find_by` instead of `find_or_create_by`
    champ = champs
      .create_with(**champ_attributes)
      .find_or_create_by!(stable_id: type_de_champ.stable_id, row_id:, stream:)

    draft_champ_exists = if stream != Champ::MAIN_STREAM
      champs.exists?(stable_id: type_de_champ.stable_id, row_id:, stream:)
    end
    main_stream_champ = if stream != Champ::MAIN_STREAM && !draft_champ_exists
      champs.find_by(stable_id: type_de_champ.stable_id, row_id:, stream: Champ::MAIN_STREAM)
    end

    # Needed when a revision change the champ type in this case, we reset the champ data
    if champ.type != champ_attributes[:type]
      champ_attributes[:value] = nil
      champ_attributes[:value_json] = nil
      champ_attributes[:external_id] = nil
      champ_attributes[:data] = nil
      champ = champ.becomes!(champ_attributes[:type].constantize)
    elsif main_stream_champ.present?
      champ.clone_value_from(main_stream_champ)
    end

    champ.assign_attributes(champ_attributes)
    champ.save!

    reset_champ_cache(champ)

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
    @champs_on_stream = nil
  end

  def reset_champ_cache(champ)
    champs_by_public_id[champ.public_id]&.reload
    reset_champs_cache
  end

  def reload_champs_cache
    champs.reset
    reset_champs_cache
  end
end
