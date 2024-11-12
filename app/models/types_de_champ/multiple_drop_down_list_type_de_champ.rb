# frozen_string_literal: true

class TypesDeChamp::MultipleDropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value(champ)
    selected_options(champ).join(', ')
  end

  def champ_value_for_tag(champ, path = :value)
    ChampPresentations::MultipleDropDownListPresentation.new(selected_options(champ))
  end

  def champ_value_for_export(champ, path = :value)
    champ_value(champ)
  end

  def champ_blank?(champ) = selected_options(champ).blank?

  private

  def selected_options(champ)
    return [] if champ.value.blank?

    if champ.is_type?(TypeDeChamp.type_champs.fetch(:drop_down_list))
      [champ.value]
    else
      JSON.parse(champ.value)
    end
  rescue JSON::ParserError
    []
  end
end
