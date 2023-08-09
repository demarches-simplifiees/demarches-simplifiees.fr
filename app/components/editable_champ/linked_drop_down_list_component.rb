class EditableChamp::LinkedDropDownListComponent < EditableChamp::EditableChampBaseComponent
  private

  def secondary_label
    secondary_label_text + secondary_label_mandatory
  end

  def secondary_label_text
    @champ.drop_down_secondary_libelle.presence || "#{@champ.libelle} : précisez"
  end

  def secondary_label_mandatory
    @champ.mandatory? ? tag.span(' *', class: 'mandatory') : ''
  end
end
