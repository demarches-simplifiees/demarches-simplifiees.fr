class TypesDeChamp::DateTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def pattern
    "/^\d{4}-\d{2}-\d{2}$/"
  end
end
