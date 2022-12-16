class EditableChamp::EditableChampBaseComponent < ApplicationComponent
  def initialize(form:, champ:, seen_at: nil)
    @form, @champ, @seen_at = form, champ, seen_at
  end

  def data_dependent_conditions
    { "dependent-conditions": "true" } if @champ.dependent_conditions?
  end
end
