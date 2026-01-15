# frozen_string_literal: true

class TiptapEditorComponent < ApplicationComponent
  attr_reader :form, :field_name

  def initialize(form:, field_name:)
    @form = form
    @field_name = field_name
  end

  def input_value
    form.object.tiptap_body_or_default
  end
end
