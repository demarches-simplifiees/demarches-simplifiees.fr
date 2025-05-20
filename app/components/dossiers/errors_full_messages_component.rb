# frozen_string_literal: true

class Dossiers::ErrorsFullMessagesComponent < ApplicationComponent
  ErrorDescriptor = Data.define(:anchor, :label, :error_message)

  def initialize(dossier:)
    @dossier = dossier
  end

  def dedup_and_partitioned_errors
    @dossier.errors.to_enum # ActiveModel::Errors.to_a is an alias to full_messages, we don't want that
      .to_a # but enum.to_a gives back an array
      .map { |error| to_error_descriptor(error) }
  end

  def to_error_descriptor(error)
    model = error.inner_error.base

    if model.respond_to?(:libelle) # a Champ or something acting as a Champ
      ErrorDescriptor.new("##{model.focusable_input_id}", model.libelle.truncate(200) + row_number_suffix(model), error.message)
    else
      ErrorDescriptor.new("##{model.model_name.singular}_#{error.attribute}", model.class.human_attribute_name(error.attribute), error.message)
    end
  end

  def row_number_suffix(model)
    return "" if !model.child?

    parent = model.dossier.revision.parent_of(model.type_de_champ)
    number = model.dossier.repetition_row_ids(parent).index(model.row_id) + 1
    " #{number}"
  end

  def render?
    !@dossier.errors.empty?
  end
end
