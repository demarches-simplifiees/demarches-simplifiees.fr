class EditableChamp::TextareaComponent < ApplicationComponent
  include HtmlToStringHelper

  def initialize(form:, champ:)
    @form, @champ = form, champ
  end
end
