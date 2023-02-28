# frozen_string_literal: true

class TypesDeChamp::PrefillAddressTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def to_assignable_attributes(champ, value)
    return if value.blank?
    { id: champ.id, value: value, external_id: value }
  end
end
