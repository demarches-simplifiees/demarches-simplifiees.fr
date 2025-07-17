# frozen_string_literal: true

class TypesDeChamp::TextTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value_for_export(champ, path = :value)
    Sanitizers::Xml.sanitize(champ_text_value(champ))
  end
end
