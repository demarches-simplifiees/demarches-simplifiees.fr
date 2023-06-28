class EditableChamp::DropDownListComponent < EditableChamp::EditableChampBaseComponent
  def select_class_names
    class_names('width-100': contains_long_option?, 'fr-select': true)
  end

  def contains_long_option?
    max_length = 100
    @champ.options.any? { _1.size > max_length }
  end
end
