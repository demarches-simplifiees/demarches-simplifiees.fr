# frozen_string_literal: true

class TypesDeChamp::COJOTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def champ_value(champ)
    "#{champ.accreditation_number} – #{champ.accreditation_birthdate}"
  end

  def champ_value_blank?(champ)
    champ.accreditation_success != true
  end
end
