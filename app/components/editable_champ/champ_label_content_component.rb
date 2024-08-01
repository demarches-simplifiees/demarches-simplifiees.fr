# frozen_string_literal: true

class EditableChamp::ChampLabelContentComponent < ApplicationComponent
  include ApplicationHelper
  include Dsfr::InputErrorable

  def initialize(form:, champ:, seen_at: nil)
    @form, @champ, @seen_at = form, champ, seen_at
    @attribute = :value
  end

  def highlight_if_unseen_class
    if highlight?
      'highlighted'
    end
  end

  def highlight?
    @champ.updated_at.present? && @seen_at&.<(@champ.updated_at)
  end
end
