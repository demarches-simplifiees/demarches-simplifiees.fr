# frozen_string_literal: true

class EditableChamp::ReferentielComponent < EditableChamp::EditableChampBaseComponent
  delegate :type_de_champ, to: :@champ
  delegate :referentiel, to: :type_de_champ
  delegate :exact_match?, to: :referentiel

  def dsfr_input_classname
    exact_match? ? 'fr-text' : nil
  end
end
