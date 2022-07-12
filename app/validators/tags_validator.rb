class TagsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    procedure = record.procedure
    tags = record.used_type_de_champ_tags(value || '')

    invalid_tags = tags.filter_map do |(tag, stable_id)|
      tag if stable_id.nil?
    end

    invalid_for_draft_revision = invalid_tags_for_revision(record, attribute, tags, procedure.draft_revision_id)

    invalid_for_published_revision = if procedure.published_revision_id.present?
      invalid_tags_for_revision(record, attribute, tags, procedure.published_revision_id)
    else
      []
    end

    invalid_for_previous_revision = procedure
      .revision_ids_with_pending_dossiers
      .flat_map do |revision_id|
        invalid_tags_for_revision(record, attribute, tags, revision_id)
      end.uniq

    # champ is added in draft revision but not yet published
    (invalid_for_published_revision - invalid_for_draft_revision).each do |tag|
      record.errors.add(attribute, :champ_missing_in_published_revision, tag: tag)
    end

    # champ is removed but the removal is not yet published
    (invalid_for_draft_revision - invalid_for_published_revision).each do |tag|
      record.errors.add(attribute, :champ_missing_in_draft_revision, tag: tag)
    end

    # champ is removed and the removal is published
    invalid_for_published_revision.intersection(invalid_for_draft_revision).each do |tag|
      record.errors.add(attribute, :champ_missing_in_published_and_draft_revision, tag: tag)
    end

    # champ is missing from one of the revisions in pending dossiers
    invalid_for_previous_revision.each do |tag|
      record.errors.add(attribute, :champ_missing_in_previous_revision, tag: tag)
    end

    # unknown champ
    invalid_tags.each do |tag|
      record.errors.add(attribute, :champ_missing, tag: tag)
    end
  end

  def invalid_tags_for_revision(record, attribute, tags, revision_id)
    revision_stable_ids = TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(procedure_revision_types_de_champ: { revision_id: revision_id, parent_id: nil })
      .distinct(:stable_id)
      .pluck(:stable_id)

    tags.filter_map do |(tag, stable_id)|
      if stable_id.present? && !stable_id.in?(revision_stable_ids)
        tag
      end
    end
  end
end
