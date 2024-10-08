# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  class << self
    def champ_value(champ)
      if champ.value.present? && champ.drop_down_options.include?(champ.value)
        champ.value
      else
        champ_default_value
      end
    end

    def champ_value_for_export(champ, path = :value)
      if path == :value && champ.value.present? && champ.drop_down_options.include?(champ.value)
        champ.value
      else
        champ_default_export_value(path)
      end
    end
  end
end
