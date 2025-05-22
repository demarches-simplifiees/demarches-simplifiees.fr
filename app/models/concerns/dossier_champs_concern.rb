module DossierChampsConcern
  extend ActiveSupport::Concern

  def champs_for_revision(scope: nil, root: false)
    champs_index = champs.group_by(&:stable_id)
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

  def project_champ(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
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

  def champ_for_export(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if champ.blank? || !champ.visible?
      nil
    else
      champ
    end
  end

  private

  def champs_by_public_id
    @champs_by_public_id ||= champs.sort_by(&:id).index_by(&:public_id)
  end

  def champ_attributes_by_public_id(public_id, attributes, scope, updated_by:)
    stable_id, row_id = public_id.split('-')
    type_de_champ = find_type_de_champ_by_stable_id(stable_id, scope)
    champ_with_attributes_for_update(type_de_champ, row_id, updated_by:).last.merge(attributes)
  end

  def champ_with_attributes_for_update(type_de_champ, row_id, updated_by:)
    attributes = type_de_champ.params_for_champ
    # TODO: Once we have the right index in place, we should change this to use `create_or_find_by` instead of `find_or_create_by`
    champ = champs
      .create_with(**attributes)
      .find_or_create_by!(stable_id: type_de_champ.stable_id, row_id:)

    attributes[:id] = champ.id
    attributes[:updated_by] = updated_by

    # Needed when a revision change the champ type in this case, we reset the champ data
    if champ.type != attributes[:type]
      attributes[:value] = nil
      attributes[:value_json] = nil
      attributes[:external_id] = nil
      attributes[:data] = nil
    end

    parent = revision.parent_of(type_de_champ)
    if parent.present?
      attributes[:parent] = champs.find { _1.stable_id == parent.stable_id }
    else
      attributes[:parent] = nil
    end

    @champs_by_public_id = nil

    [champ, attributes]
  end
end
