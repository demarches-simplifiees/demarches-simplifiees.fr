# frozen_string_literal: true

class TypesDeChamp::CnafTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end
end
