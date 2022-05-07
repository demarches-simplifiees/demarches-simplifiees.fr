class TypesDeChamp::MultipleDropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def condition_operators
    [
      ['Est', 'is'],
      ['N’est pas', 'is_not'],
      ['Est remplie', 'is_not_blank'],
      ['N’est pas remplie', 'is_blank']
    ]
  end

  def condition_values
    @type_de_champ.drop_down_list_enabled_non_empty_options.map do |option|
      [option, option]
    end
  end
end
