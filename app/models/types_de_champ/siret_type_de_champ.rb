# frozen_string_literal: true

class TypesDeChamp::SiretTypeDeChamp < TypesDeChamp::TypeDeChampBase
  # pf commune, code postal, department, region are not filled for Numéro Tahiti
  # include AddressableColumnConcern

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end
end
