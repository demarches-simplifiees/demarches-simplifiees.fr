class EditableChamp::ChampLabelContentComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(champ:, seen_at: nil)
    @champ, @seen_at = champ, seen_at
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
