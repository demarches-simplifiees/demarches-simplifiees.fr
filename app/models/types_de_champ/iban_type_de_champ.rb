# frozen_string_literal: true

class TypesDeChamp::IbanTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_value_for_api(champ, version: 2)
    champ_value(champ).gsub(/\s+/, '')
  end
end
