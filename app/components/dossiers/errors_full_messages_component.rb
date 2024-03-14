# frozen_string_literal: true

class Dossiers::ErrorsFullMessagesComponent < ApplicationComponent
  ErrorDescriptor = Data.define(:anchor, :label, :error_message)

  def initialize(dossier:, errors:)
    @dossier = dossier
    @errors = errors
  end

  def dedup_and_partitioned_errors
    formated_errors = @errors.to_enum # ActiveModel::Errors.to_a is an alias to full_messages, we don't want that
      .to_a # but enum.to_a gives back an array
      .uniq { |error| [error.inner_error.base] } # dedup cumulated errors from dossier.champs, dossier.champs_public, dossier.champs_private which run the validator one time per association
      .map { |error| to_error_descriptor(error) }
    yield(Array(formated_errors[0..2]), Array(formated_errors[3..]))
  end

  def to_error_descriptor(error)
    model = error.inner_error.base

    if model.respond_to?(:libelle) # a Champ or something acting as a Champ
      ErrorDescriptor.new("##{model.labelledby_id}", model.libelle.truncate(200), error.message)
    else
      ErrorDescriptor.new("##{model.model_name.singular}_#{error.attribute}", model.class.human_attribute_name(error.attribute), error.message)
    end
  end

  def render?
    !@errors.empty?
  end
end
