# frozen_string_literal: true

class TypesDeChamp::PrefillAnnuaireEducationTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def to_assignable_attributes(champ, value)
    return nil if value.blank?

    {
      id: champ.id,
      external_id: value,
      value: value
    }
  end
end
