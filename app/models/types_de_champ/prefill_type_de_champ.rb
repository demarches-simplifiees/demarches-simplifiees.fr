class TypesDeChamp::PrefillTypeDeChamp < SimpleDelegator
  POSSIBLE_VALUES_THRESHOLD = 5

  def self.build(type_de_champ)
    case type_de_champ.type_champ
    when TypeDeChamp.type_champs.fetch(:drop_down_list)
      TypesDeChamp::PrefillDropDownListTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)
      TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:pays)
      TypesDeChamp::PrefillPaysTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:regions)
      TypesDeChamp::PrefillRegionTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:departements)
      TypesDeChamp::PrefillDepartementTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:epci)
      TypesDeChamp::PrefillEpciTypeDeChamp.new(type_de_champ)
    else
      new(type_de_champ)
    end
  end

  def self.wrap(collection)
    collection.map { |type_de_champ| build(type_de_champ) }
  end

  def possible_values
    []
  end

  def example_value
    return nil unless prefillable?

    I18n.t("views.prefill_descriptions.edit.examples.#{type_champ}")
  end

  def too_many_possible_values?
    possible_values.count > POSSIBLE_VALUES_THRESHOLD
  end

  def transform_value_to_assignable_attributes(value)
    { value: value }
  end
end
