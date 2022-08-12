class EditableChamp::MesriComponent < ApplicationComponent
  def initialize(form:, champ:)
    @form, @champ = form, champ
  end
end
