# frozen_string_literal: true

class TypesDeChamp::PrefillSiretTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def example_value
    "130 025 265 00013"
  end

  def to_assignable_attributes(champ, value)
    { id: champ.id, external_id: value.presence }
  end
end
