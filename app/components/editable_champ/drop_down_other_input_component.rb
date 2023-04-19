class EditableChamp::DropDownOtherInputComponent < EditableChamp::EditableChampBaseComponent
  def render?
    @champ.other?
  end
end
