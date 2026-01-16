# frozen_string_literal: true

class TypesDeChamp::DatetimeTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value(champ)
    I18n.l(Time.zone.parse(champ.value), format: :long_with_time)
  end
end
