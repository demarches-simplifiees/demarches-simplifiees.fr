# frozen_string_literal: true

class TypesDeChamp::COJOTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def champ_value(champ)
    "#{champ.accreditation_number} – #{champ.accreditation_birthdate}"
  end
end
