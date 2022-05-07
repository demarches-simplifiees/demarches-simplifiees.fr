class TypesDeChamp::TextTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def condition_operators
    [
      ['Est', 'is'],
      ['N’est pas', 'is_not'],
      ['Contient', 'contains'],
      ['Est remplie', 'is_not_blank'],
      ['N’est pas remplie', 'is_blank']
    ]
  end

  def condition_values
    :text
  end

  def default_condition_value
    ''
  end
end
