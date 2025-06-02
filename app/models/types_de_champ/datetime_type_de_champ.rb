# frozen_string_literal: true

class TypesDeChamp::DatetimeTypeDeChamp < TypesDeChamp::TypeDeChampBase
  class << self
    def champ_value(champ)
      I18n.l(Time.zone.parse(champ.value))
    end

    def champ_value_for_export(champ, path = nil)
      Time.zone.parse(champ.value)
    end
  end
end
