# frozen_string_literal: true

class TypesDeChamp::MultipleDropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value_for_tag(champ, path = :value)
    ChampPresentations::MultipleDropDownListPresentation.new(selected_options(champ))
  end

  def champ_blank?(champ) = selected_options(champ).blank?

  def self.parse_selected_options(champ)
    return [] if champ.value.blank?

    if champ.is_type?(TypeDeChamp.type_champs.fetch(:drop_down_list))
      [champ.value]
    else
      JSON.parse(champ.value)
    end
  rescue JSON::ParserError
    []
  end

  private

  def selected_options(champ)
    self.class.parse_selected_options(champ)
  end
end
