class TypesDeChamp::SiretTypeDeChamp < TypesDeChamp::TypeDeChampBase
  include AddressableFacetConcern

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end
end
