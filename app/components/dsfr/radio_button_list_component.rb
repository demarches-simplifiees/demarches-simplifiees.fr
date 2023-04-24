class Dsfr::RadioButtonListComponent < ApplicationComponent
  def initialize(form:, target:, buttons:)
    @form = form
    @target = target
    @buttons = buttons
  end
end
