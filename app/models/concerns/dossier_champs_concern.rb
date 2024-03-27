module DossierChampsConcern
  extend ActiveSupport::Concern

  def find_public_type_de_champ!(stable_id)
    revision.types_de_champ.public_only.find_by!(stable_id:)
  end

  def find_private_type_de_champ!(stable_id)
    revision.types_de_champ.private_only.find_by!(stable_id:)
  end

  def project_champ(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if champ.nil?
      type_de_champ.build_champ(dossier: self, row_id:)
    else
      champ
    end
  end

  # Get all the champs values for the types de champ in the final list.
  # Dossier might not have corresponding champ – display nil.
  # To do so, we build a virtual champ when there is no value so we can call for_export with all indexes
  def champs_for_export(types_de_champ, row_id = nil)
    types_de_champ.flat_map do |type_de_champ|
      champ = champ_for_export(type_de_champ, row_id)

      # nil => [nil]
      # text => [text]
      # [commune, insee, departement] => [commune, insee, departement]
      wrapped_exported_values = [champ.for_export].flatten

      wrapped_exported_values.map.with_index do |champ_value, index|
        [type_de_champ.libelle_for_export(index), champ_value]
      end
    end
  end

  def champs_for_prefill(stable_ids)
    revision
      .types_de_champ
      .filter { _1.stable_id.in?(stable_ids) }
      .filter { !revision.child?(_1) }
      .map { champ_for_update(_1, nil) }
  end

  def champ_for_update(type_de_champ, row_id)
    champ, attributes = champ_with_attributes_for_update(type_de_champ, row_id)
    champ.assign_attributes(attributes)
    champ
  end

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

  def update_champs_public(attributes)
    # TODO: remove after one deploy
    if attributes.present? && attributes.values.filter { _1.key?(:with_public_id) }.empty?
      assign_attributes(champs_public_all_attributes: attributes)
      @champs_by_public_id = nil
      return
    end

    champs_attributes = attributes
      .keys
      .map do
        stable_id, row_id = _1.split('-')
        type_de_champ = revision.types_de_champ.public_only.find_by!(stable_id:)
        champ_with_attributes_for_update(type_de_champ, row_id).last.merge(attributes[_1])
      end

    assign_attributes(champs_attributes:)
  end

  def update_champs_private(attributes)
    # TODO: remove after one deploy
    if attributes.present? && attributes.values.filter { _1.key?(:with_public_id) }.empty?
      assign_attributes(champs_private_all_attributes: attributes)
      @champs_by_public_id = nil
      return
    end

    champs_attributes = attributes
      .keys
      .map do
        stable_id, row_id = _1.split('-')
        type_de_champ = revision.types_de_champ.private_only.find_by!(stable_id:)
        champ_with_attributes_for_update(type_de_champ, row_id).last.merge(attributes[_1])
      end

    assign_attributes(champs_attributes:)
  end

  private

  def champs_by_public_id
    @champs_by_public_id ||= champs.sort_by(&:id).index_by(&:public_id)
  end

  def champ_for_export(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if champ.blank? || !champ.visible?
      nil
    else
      champ
    end
  end

  def champ_with_attributes_for_update(type_de_champ, row_id)
    attributes = type_de_champ.params_for_champ
    # TODO: Once we have the right index in place, we should change this to use `create_or_find_by` instead of `find_or_create_by`
    champ = champs
      .create_with(type_de_champ:, **attributes)
      .find_or_create_by(stable_id: type_de_champ.stable_id, row_id:)

    attributes[:id] = champ.id

    if champ.type != attributes[:type]
      attributes[:value] = nil
      attributes[:value_json] = nil
      attributes[:external_id] = nil
      attributes[:data] = nil
    end

    parent = revision.parent_of(type_de_champ)
    if parent.present?
      attributes[:parent] = champs.find { _1.type_de_champ_id == parent.id }
    else
      attributes[:parent] = nil
    end

    @champs_by_public_id = nil

    return champ, attributes
  end
end
