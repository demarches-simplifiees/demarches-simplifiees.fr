class TypesDeChamp::CheckboxTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def pattern
    "^(true|false)$"
  end
end
