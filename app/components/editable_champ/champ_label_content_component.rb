class EditableChamp::ChampLabelContentComponent < ApplicationComponent
  def initialize(champ:, seen_at: nil)
    @champ, @seen_at = champ, seen_at
  end
end
