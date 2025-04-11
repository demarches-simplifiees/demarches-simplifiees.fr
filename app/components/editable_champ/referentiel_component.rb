# frozen_string_literal: true

class EditableChamp::ReferentielComponent < EditableChamp::EditableChampBaseComponent
  delegate :type_de_champ, to: :@champ
  delegate :referentiel, to: :type_de_champ
  delegate :exact_match?, to: :referentiel, allow_nil: true

  def dsfr_input_classname
    exact_match? ? 'fr-input' : nil
  end
end
