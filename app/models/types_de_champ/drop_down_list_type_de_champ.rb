# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_blank?(champ)
    super || !champ_value_in_options?(champ)
  end

  private

  def champ_value_in_options?(champ)
    champ_with_other_value?(champ) || drop_down_options.include?(champ.value)
  end

  def champ_with_other_value?(champ)
    drop_down_other? && champ.value_json&.fetch('other', false)
  end
end
