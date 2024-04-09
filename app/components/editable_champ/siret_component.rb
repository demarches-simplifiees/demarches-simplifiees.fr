class EditableChamp::SiretComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
    end

  def hint_id
    dom_id(@champ, :siret_info)
  end

  def hintable?
    true
  end
end
