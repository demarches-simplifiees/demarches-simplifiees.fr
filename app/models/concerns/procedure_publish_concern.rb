# frozen_string_literal: true

module ProcedurePublishConcern
  extend ActiveSupport::Concern

  def publish_or_reopen!(administrateur, path)
    Procedure.transaction do
      if brouillon?
        reset!
      end

      other_procedure = other_procedure_with_path(path)
      claim_path!(administrateur, path)
      if other_procedure.present?
        other_procedure.unpublish! if other_procedure.may_unpublish?

        publish!(administrateur, other_procedure.canonical_procedure || other_procedure)
      else
        publish!(administrateur, nil)
      end
    end
  end

  def publish_revision!(administrateur)
    reset!

    transaction { publish_new_revision(administrateur) }

    dossiers
      .state_not_termine
      .find_each(&:rebase_later)
  end

  def reset_draft_revision!
    if published_revision.present? && draft_changed?
      reset!
      transaction do
        draft_revision.types_de_champ.filter(&:only_present_on_draft?).each(&:destroy)
        draft_revision.update(dossier_submitted_message: nil)
        draft_revision.destroy
        update!(draft_revision: create_new_revision(published_revision))
      end
    end
  end

  def reset!
    if !locked? || draft_changed?
      dossier_ids_to_destroy = draft_revision.dossiers.ids
      if dossier_ids_to_destroy.present?
        Rails.logger.info("Resetting #{dossier_ids_to_destroy.size} dossiers on procedure #{id}: #{dossier_ids_to_destroy}")
        draft_revision.dossiers.destroy_all
      end
    end
  end

  def before_publish
    assign_attributes(closed_at: nil, unpublished_at: nil)
  end

  def after_publish(administrateur, canonical_procedure = nil)
    self.canonical_procedure = canonical_procedure

    touch(:published_at)
    publish_new_revision(administrateur)
  end

  def after_republish(administrateur, canonical_procedure = nil)
    touch(:published_at)
  end

  def after_close
    touch(:closed_at)
  end

  def after_unpublish
    touch(:unpublished_at)
  end

  def create_new_revision(revision = nil)
    transaction do
      new_revision = (revision || draft_revision)
        .deep_clone(include: [:revision_types_de_champ])
        .tap { |revision| revision.published_at = nil }
        .tap { |revision| revision.administrateur_id = nil }
        .tap(&:save!)

      move_new_children_to_new_parent_coordinate(new_revision)

      new_revision
    end
  end

  private

  def publish_new_revision(administrateur)
    cleanup_types_de_champ_options!
    cleanup_types_de_champ_children!
    nullify_unused_referentiels
    self.published_revision = draft_revision
    self.draft_revision = create_new_revision
    save!(context: :publication)
    published_revision.update_columns(published_at: Time.current, administrateur_id: administrateur.id)
  end

  def move_new_children_to_new_parent_coordinate(new_draft)
    children = new_draft.revision_types_de_champ
      .includes(parent: :type_de_champ)
      .where.not(parent_id: nil)
    coordinates_by_stable_id = new_draft.revision_types_de_champ
      .includes(:type_de_champ)
      .index_by(&:stable_id)

    children.each do |child|
      child.update!(parent: coordinates_by_stable_id.fetch(child.parent.stable_id))
    end
    new_draft.reload
  end

  def cleanup_types_de_champ_options!
    draft_revision.types_de_champ.each do |type_de_champ|
      type_de_champ.update!(options: type_de_champ.clean_options)
    end
  end

  def cleanup_types_de_champ_children!
    draft_revision.revision_types_de_champ
      .filter(&:orphan?)
      .each { draft_revision.remove_type_de_champ(_1.stable_id) }
  end

  def nullify_unused_referentiels
    draft_revision.types_de_champ
      .reject { _1.drop_down_list? || _1.multiple_drop_down_list? || _1.referentiel? }
      .each do |type_de_champ|
        type_de_champ.update!(referentiel_id: nil)
      end
  end
end
