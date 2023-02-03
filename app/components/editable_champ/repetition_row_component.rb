class EditableChamp::RepetitionRowComponent < ApplicationComponent
  def initialize(form:, champ:, row:, seen_at: nil)
    @form, @champ, @row, @seen_at = form, champ, row, seen_at
  end
end
