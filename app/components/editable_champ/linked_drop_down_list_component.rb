class EditableChamp::LinkedDropDownListComponent < ApplicationComponent
  include StringToHtmlHelper

  def initialize(form:, champ:)
    @form, @champ = form, champ
  end
end
