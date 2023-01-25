class TypesDeChamp::RNATypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def pattern
    "^W\d{9}$"
  end
end
