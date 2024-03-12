class Dsfr::ToggleComponent < ApplicationComponent
  def initialize(form:, target:, title:, disabled: nil, hint: nil, toggle_labels: { checked: 'Activé', unchecked: 'Désactivé' }, opt: nil)
    @form = form
    @target = target
    @title = title
    @hint = hint
    @disabled = disabled
    @toggle_labels = toggle_labels
    @opt = opt
  end

  attr_reader :toggle_labels
end
