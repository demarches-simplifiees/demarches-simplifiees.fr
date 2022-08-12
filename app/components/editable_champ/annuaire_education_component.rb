class EditableChamp::AnnuaireEducationComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(form:, champ:)
    @form, @champ = form, champ
  end
end
