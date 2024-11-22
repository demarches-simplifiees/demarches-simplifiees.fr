# frozen_string_literal: true

class Dsfr::ToggleComponent < ApplicationComponent
  attr_reader :target
  attr_reader :title
  attr_reader :hint
  attr_reader :toggle_labels
  attr_reader :disabled
  attr_reader :data
  attr_reader :extra_class_names

  def initialize(form:, target:, title:, disabled: nil, hint: nil, toggle_labels: { checked: 'Activé', unchecked: 'Désactivé' }, opt: nil, extra_class_names: nil)
    @form = form
    @target = target
    @title = title
    @hint = hint
    @disabled = disabled
    @toggle_labels = toggle_labels
    @data = opt
    @extra_class_names = extra_class_names
  end

  private

  def input_id
    dom_id(@form.object, target)
  end
end
