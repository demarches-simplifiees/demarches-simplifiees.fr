# frozen_string_literal: true

class Procedure::FixedFooterComponent < ApplicationComponent
  def initialize(procedure:, form: nil, is_form_disabled: nil, extra_class_names: nil)
    @procedure = procedure
    @form = form
    @is_form_disabled = is_form_disabled
    @extra_class_names = extra_class_names
  end

  attr_reader :form, :is_form_disabled, :extra_class_names
end
