class TypesDeChamp::DatetimeTypeDeChamp < TypesDeChamp::TypeDeChampBase
  class << self
    def champ_value(champ)
      I18n.l(Time.zone.parse(champ.value))
    end
  end
end
