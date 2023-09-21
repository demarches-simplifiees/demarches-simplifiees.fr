class EditableChamp::CheckboxComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_champ_container
    :fieldset
  end

  def dsfr_input_classname
    'fr-radio'
  end
end
