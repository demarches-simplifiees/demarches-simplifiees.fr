# frozen_string_literal: true

class EditableChamp::ReferentielDisplayComponent < Referentiels::ReferentielDisplayBaseComponent
  delegate :type_de_champ, to: :@champ
  delegate :referentiel_mapping_displayable_for_usager, to: :type_de_champ

  def data
    safe_value_json = Hash(@champ.value_json).with_indifferent_access

    referentiel_mapping_displayable_for_usager.filter_map do |jsonpath, _mapping|
      value = format(jsonpath, safe_value_json.dig(jsonpath))
      [libelle(jsonpath), value] if !value.nil?
    end
  end
end
