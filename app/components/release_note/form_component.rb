# frozen_string_literal: true

class ReleaseNote::FormComponent < ApplicationComponent
  attr_reader :release_note

  def initialize(release_note:)
    @release_note = release_note
  end

  private

  def categories_fieldset_class
    class_names(
      "fr-fieldset--error": categories_error?
    )
  end

  def categories_error?
    release_note.errors.key?(:categories)
  end

  def categories_errors_describedby_id
    return nil if !categories_error?

    dom_id(release_note, "categories_errors")
  end

  def categories_full_messages_errors
    release_note.errors.full_messages_for(:categories)
  end
end
