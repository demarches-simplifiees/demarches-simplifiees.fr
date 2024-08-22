# frozen_string_literal: true

class Dsfr::ToggleComponent < ApplicationComponent
  def initialize(form:, target:, title:, disabled: nil, hint: nil, toggle_labels: { checked: 'Activé', unchecked: 'Désactivé' }, opt: nil, extra_class_names: nil)
    @form = form
    @target = target
    @title = title
    @hint = hint
    @disabled = disabled
    @toggle_labels = toggle_labels
    @opt = opt
    @extra_class_names = extra_class_names
  end

  attr_reader :toggle_labels, :extra_class_names
end
