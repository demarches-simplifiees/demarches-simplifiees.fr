# frozen_string_literal: true

class EditableChamp::ReferentielDisplayComponent < Referentiels::ReferentielDisplayBaseComponent
  def data
    Hash(@champ.value_json&.with_indifferent_access)
      &.dig(:display_usager)
      &.map { |jsonpath, value| [libelle(jsonpath), format(jsonpath, value)] }
      &.reject { |_jsonpath, value| value.nil? }
  end
end
