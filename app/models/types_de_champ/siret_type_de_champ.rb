class TypesDeChamp::SiretTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def pattern
    "^\d{14}$"
  end
end
