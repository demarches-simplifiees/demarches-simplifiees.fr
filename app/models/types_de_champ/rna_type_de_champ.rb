# frozen_string_literal: true

class TypesDeChamp::RNATypeDeChamp < TypesDeChamp::TypeDeChampBase
  include AddressableColumnConcern

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_value_for_export(champ, path = :value)
    champ.identifier
  end
end
