class TypesDeChamp::NumberTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def pattern
    "^-?(?:\d|.)+$"
  end
end
