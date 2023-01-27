class EditableChamp::RepetitionRowComponent < ApplicationComponent
  def initialize(form:, champ:, row:)
    @form, @champ, @row = form, champ, row
  end
end
