class EditableChamp::TitreIdentiteComponent < EditableChamp::EditableChampBaseComponent
  def user_can_destroy?
    !@champ.mandatory? || @champ.dossier.brouillon?
  end

  def user_can_replace?
    @champ.mandatory? && @champ.dossier.en_construction?
  end
end
