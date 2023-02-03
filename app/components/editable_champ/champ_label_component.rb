class EditableChamp::ChampLabelComponent < ApplicationComponent
  include StringToHtmlHelper

  def initialize(form:, champ:, seen_at: nil)
    @form, @champ, @seen_at = form, champ, seen_at
  end
end
