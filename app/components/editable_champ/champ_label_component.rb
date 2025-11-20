# frozen_string_literal: true

class EditableChamp::ChampLabelComponent < ApplicationComponent
  include Dsfr::InputErrorable
  include ChampAriaLabelledbyHelper

  attr_reader :attribute

  def initialize(form:, champ:, seen_at: nil, row_number: nil)
    @form, @champ, @seen_at, @row_number = form, champ, seen_at, row_number
    @attribute = :value
  end
end
