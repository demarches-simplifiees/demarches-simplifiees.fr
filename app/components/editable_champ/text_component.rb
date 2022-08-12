class EditableChamp::TextComponent < ApplicationComponent
  def initialize(form:, champ:)
    @form, @champ = form, champ
  end
end
