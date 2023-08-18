class Dsfr::ToggleComponent < ApplicationComponent
  def initialize(form:, target:, title:, hint:, disabled:)
    @form = form
    @target = target
    @title = title
    @hint = hint
    @disabled = disabled
  end
end
