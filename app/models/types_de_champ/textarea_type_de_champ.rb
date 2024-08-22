# frozen_string_literal: true

class TypesDeChamp::TextareaTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  class << self
    def champ_value_for_export(champ, path = :value)
      ActionView::Base.full_sanitizer.sanitize(champ.value)
    end
  end
end
