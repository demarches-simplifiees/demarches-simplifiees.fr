module DossierChampsConcern
  extend ActiveSupport::Concern

  def champs_for_revision(scope: nil, root: false)
    champs_index = main_stream.group_by(&:stable_id)
      # Due to some bad data we can have multiple copies of the same champ. Ignore extra copy.
      .transform_values { _1.sort_by(&:id).uniq(&:row_id) }

    if scope.is_a?(TypeDeChamp)
      revision
        .children_of(scope)
        .flat_map { champs_index[_1.stable_id] || [] }
        .filter(&:child?) # TODO: remove once bad data (child champ without a row id) is cleaned
    else
      revision
        .types_de_champ_for(scope:, root:)
        .flat_map { champs_index[_1.stable_id] || [] }
    end
  end

  # Get all the champs values for the types de champ in the final list.
  # Dossier might not have corresponding champ – display nil.
  # To do so, we build a virtual champ when there is no value so we can call for_export with all indexes
  def champs_for_export(types_de_champ, row_id = nil)
    types_de_champ.flat_map do |type_de_champ|
      champ = champ_for_export(type_de_champ, row_id)
      type_de_champ.libelles_for_export.map do |(libelle, path)|
        [libelle, TypeDeChamp.champ_value_for_export(type_de_champ.type_champ, champ, path)]
      end
    end
  end

  def project_champ(type_de_champ, row_id, stream: Champ::MAIN_STREAM)
    champ = champs_by_public_id(stream)[type_de_champ.public_id(row_id)]
    if champ.nil?
      type_de_champ.build_champ(dossier: self, row_id:)
    else
      champ
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
      .filter { !revision.child?(_1) }
      .map { champ_for_update(_1, nil, updated_by: nil) }
  end

  def champ_for_update(type_de_champ, row_id, updated_by:)
    champ, attributes = champ_with_attributes_for_update(type_de_champ, row_id, updated_by:)
    champ.assign_attributes(attributes)
    champ
  end

  def update_champs_attributes(attributes, scope, updated_by:)
    champs_attributes = attributes.to_h.map do |public_id, attributes|
      champ_attributes_by_public_id(public_id, attributes, scope, updated_by:)
    end

    assign_attributes(champs_attributes:)
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

  def main_stream
    champs.filter(&:main_stream?)
  end

  def user_draft_stream
    champs.filter(&:user_draft_stream?)
  end

  def history_stream
    champs.filter(&:history_stream?)
  end

  def user_draft_changes?
    user_draft_stream.present?
  end

  def user_draft_changes_on_champ?(champ)
    if user_draft_changes?
      user_draft_stream.any? { _1.public_id == champ.public_id }
    end
  end

  private

  def merge_user_draft_stream
    draft_champs = champs.where(stream: Champ::USER_DRAFT_STREAM)
      .pluck(:id, :stable_id, :row_id)
      .index_by { |(_, stable_id, row_id)| [stable_id, row_id].compact }
      .transform_values(&:first)

    main_champs = champs.where(stream: Champ::MAIN_STREAM)
      .pluck(:id, :stable_id, :row_id)
      .index_by { |(_, stable_id, row_id)| [stable_id, row_id].compact }
      .transform_values(&:first)

    draft_champ_ids = draft_champs.values
    main_champ_ids = main_champs.filter_map do |key, id|
      id if draft_champs.key?(key)
    end

    now = Time.zone.now
    transaction do
      champs.where(id: main_champ_ids, stream: Champ::MAIN_STREAM).update_all(stream: "#{Champ::HISTORY_STREAM}#{now}")
      champs.where(id: draft_champ_ids, stream: Champ::USER_DRAFT_STREAM).update_all(stream: Champ::MAIN_STREAM, updated_at: now)
    end

    reload_champs_cache
  end

  def champs_by_public_id(stream = Champ::MAIN_STREAM)
    case stream
    when Champ::MAIN_STREAM
      @champs_by_public_id ||= main_stream.sort_by(&:updated_at).index_by(&:public_id)
    when Champ::USER_DRAFT_STREAM
      @draft_user_champs_by_public_id ||= user_draft_stream.sort_by(&:updated_at).index_by(&:public_id)
    end
  end

  def champ_for_export(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if champ.blank? || !champ.visible?
      nil
    else
      champ
    end
  end

  def champ_attributes_by_public_id(public_id, attributes, scope, updated_by:)
    stable_id, row_id = public_id.split('-')
    type_de_champ = find_type_de_champ_by_stable_id(stable_id, scope)
    champ_with_attributes_for_update(type_de_champ, row_id, updated_by:).last.merge(attributes)
  end

  def champ_with_attributes_for_update(type_de_champ, row_id, updated_by:)
    stream = if type_de_champ.public? && use_streams?
      Champ::USER_DRAFT_STREAM
    else
      Champ::MAIN_STREAM
    end

    attributes = type_de_champ.params_for_champ
    attributes[:stream] = stream

    draft_stream_champ = if stream != Champ::MAIN_STREAM
      champs.exists?(stable_id: type_de_champ.stable_id, row_id:, stream:)
    end
    main_stream_champ = if stream != Champ::MAIN_STREAM && !draft_stream_champ
      champs.find_by(stable_id: type_de_champ.stable_id, row_id:, stream: Champ::MAIN_STREAM)
    end

    champ = champs
      .create_with(**attributes)
      .create_or_find_by!(stable_id: type_de_champ.stable_id, row_id:, stream:)

    attributes[:id] = champ.id
    attributes[:updated_by] = updated_by

    # Needed when a revision change the champ type in this case, we reset the champ data
    if champ.type != attributes[:type]
      attributes[:value] = nil
      attributes[:value_json] = nil
      attributes[:external_id] = nil
      attributes[:data] = nil
    elsif main_stream_champ.present?
      champ.clone_value_from(main_stream_champ)
    end

    parent = revision.parent_of(type_de_champ)
    if parent.present?
      attributes[:parent] = champs.find { _1.stable_id == parent.stable_id }
    else
      attributes[:parent] = nil
    end

    reset_champs_cache

    [champ, attributes]
  end

  def use_streams?
    procedure.feature_enabled?(:user_draft_stream) && en_construction? && editing_forks.empty?
  end

  def reset_champs_cache
    @champs_by_public_id = nil
    @draft_user_champs_by_public_id = nil
  end

  def reload_champs_cache
    champs.reload
    @champs_by_public_id = nil
    @draft_user_champs_by_public_id = nil
  end
end
