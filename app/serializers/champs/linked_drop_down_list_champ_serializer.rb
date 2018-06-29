class Champs::LinkedDropDownListChampSerializer < ChampSerializer
  def value
    { primary: object.primary_value, secondary: object.secondary_value }
  end
end
