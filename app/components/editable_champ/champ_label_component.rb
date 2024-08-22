# frozen_string_literal: true

class EditableChamp::ChampLabelComponent < ApplicationComponent
  include Dsfr::InputErrorable

  def initialize(form:, champ:, seen_at: nil)
    @form, @champ, @seen_at = form, champ, seen_at
    @attribute = :value
  end
end
