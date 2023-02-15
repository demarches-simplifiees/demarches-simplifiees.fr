# frozen_string_literal: true

class TypesDeChamp::PrefillAnnuaireEducationTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def to_assignable_attributes(champ, value)
    return nil if value.blank?
    return nil unless (data = APIEducation::AnnuaireEducationAdapter.new(value.presence).to_params)

    {
      id: champ.id,
      external_id: data['identifiant_de_l_etablissement'],
      value: "#{data['nom_etablissement']}, #{data['nom_commune']} (#{data['identifiant_de_l_etablissement']})"
    }
  rescue APIEducation::AnnuaireEducationAdapter::InvalidSchemaError
    nil
  end
end
