class TypesDeChamp::IbanTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def pattern
    "^[A-Z]{2}[0-9]{2}[A-Z0-9]{4}\d{7}([A-Z0-9]?){0,16}$"
  end
end
