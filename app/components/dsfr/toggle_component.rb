# frozen_string_literal: true

class Dsfr::ToggleComponent < ApplicationComponent
  attr_reader :target
  attr_reader :title
  attr_reader :html_title
  attr_reader :hint
  attr_reader :toggle_labels
  attr_reader :disabled
  attr_reader :data
  attr_reader :extra_class_names

  def initialize(form:, target:, title: nil, html_title: nil, disabled: nil, hint: nil, toggle_labels: { checked: 'Activé', unchecked: 'Désactivé' }, opt: nil, extra_class_names: "fr-toggle--label-left")
    @form = form
    @target = target
    @title = title
    @html_title = html_title
    @hint = hint
    @disabled = disabled
    @toggle_labels = toggle_labels
    @data = opt
    @extra_class_names = extra_class_names
  end

  private

  def label_for
    return input_id if @form.object.present?

    return "#{@form.options[:namespace]}_#{target}" if @form.options[:namespace].present?

    target.to_s
  end

  def input_id
    if @form.object.present?
      dom_id(@form.object, target)
    else
      target.to_s
    end
  end
end
