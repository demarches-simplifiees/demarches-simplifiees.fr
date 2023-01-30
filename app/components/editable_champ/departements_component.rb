class EditableChamp::DepartementsComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(form:, champ:)
    @form, @champ = form, champ
  end
end
