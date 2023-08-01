class EditableChamp::CarteComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def initialize(**args)
    super(**args)

    @autocomplete_component = EditableChamp::ComboSearchComponent.new(**args)
  end
end
