class TypesDeChamp::CheckboxTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def condition_operators
    [
      ['Est', 'is'],
      ['N’est pas', 'is_not'],
      ['Est remplie', 'is_not_blank'],
      ['N’est pas remplie', 'is_blank']
    ]
  end

  def condition_values
    [
      ['Oui', true],
      ['Non', false]
    ]
  end
end
