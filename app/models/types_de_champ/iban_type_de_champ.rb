class TypesDeChamp::IbanTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end
end
