class EditableChamp::DropDownListComponent < EditableChamp::EditableChampBaseComponent
  def select_class_names
    class_names('width-100': contains_long_option?)
  end

  def contains_long_option?
    max_length = 100
    @champ.options.map(&:size).any? { _1 > max_length }
  end
end
