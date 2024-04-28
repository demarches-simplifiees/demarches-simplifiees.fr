# frozen_string_literal: true

class EditableChamp::TitreIdentiteComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
    end

  def user_can_destroy?
    !@champ.mandatory? || @champ.dossier.brouillon?
  end
end
