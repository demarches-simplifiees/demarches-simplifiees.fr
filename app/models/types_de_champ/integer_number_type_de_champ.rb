class TypesDeChamp::IntegerNumberTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def condition_operators
    [
      ['Est', 'is'],
      ['N’est pas', 'is_not'],
      ['>', 'gt'],
      ['≥', 'gte'],
      ['<', 'lt'], 
      ['≤', 'lte'],
    ]
  end

  def condition_values
    :number
  end

  def default_condition_value
    0
  end
end
