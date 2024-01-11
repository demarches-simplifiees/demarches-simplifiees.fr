class EditableChamp::TitreIdentiteComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
    end

  def user_can_destroy?
    !@champ.mandatory? || @champ.dossier.brouillon?
  end

  def user_can_replace?
    @champ.mandatory? && @champ.dossier.en_construction?
  end
end
