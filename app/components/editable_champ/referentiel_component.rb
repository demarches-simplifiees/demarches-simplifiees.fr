# frozen_string_literal: true

class EditableChamp::ReferentielComponent < EditableChamp::EditableChampBaseComponent
  delegate :type_de_champ, to: :@champ
  delegate :referentiel,
           :safe_referentiel_mapping,
           to: :type_de_champ
  delegate :exact_match?, to: :referentiel, allow_nil: true

  def dsfr_input_classname
    exact_match? ? 'fr-input' : nil
  end

  def display_usager?
    display_usager.present?
  end

  def display_usager
    Hash(@champ.value_json.with_indifferent_access&.dig(:display_usager))
  end

  def libelle(jsonpath)
    safe_referentiel_mapping[jsonpath]&.dig(:libelle).presence || jsonpath
  end
end
