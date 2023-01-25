class TypesDeChamp::PhoneTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def pattern
    "^(?:(?:\+|00)\d{2,3}|0)\s*[1-9](?:[\s.-]*\d{2}){4}$"
  end
end
