# frozen_string_literal: true

class TypesDeChamp::MultipleDropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  class << self
    def champ_value(champ)
      champ.selected_options.join(', ')
    end

    def champ_value_for_tag(champ, path = :value)
      ChampPresentations::MultipleDropDownListPresentation.new(champ.selected_options)
    end

    def champ_value_for_export(champ, path = :value)
      champ.selected_options.join(', ')
    end
  end
end
