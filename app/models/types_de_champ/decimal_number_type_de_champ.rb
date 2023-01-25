class TypesDeChamp::DecimalNumberTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def pattern
    "^-?(?:\d|.)+$"
  end
end
