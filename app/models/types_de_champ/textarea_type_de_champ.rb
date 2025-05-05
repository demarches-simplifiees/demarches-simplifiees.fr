# frozen_string_literal: true

class TypesDeChamp::TextareaTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_value_for_export(champ, path = :value)
    Sanitizers::Xml.sanitize(ActionView::Base.full_sanitizer.sanitize(champ.value))
  end
end
