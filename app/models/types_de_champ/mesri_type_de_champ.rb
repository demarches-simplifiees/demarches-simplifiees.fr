# frozen_string_literal: true

class TypesDeChamp::MesriTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end
end
