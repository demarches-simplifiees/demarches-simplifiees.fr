class EditableChamp::DecimalNumberComponent < ApplicationComponent
  def initialize(form:, champ:)
    @form, @champ = form, champ
  end
end
