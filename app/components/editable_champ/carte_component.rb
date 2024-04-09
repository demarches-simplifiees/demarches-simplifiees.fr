class EditableChamp::CarteComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper
  def dsfr_champ_container
    :fieldset
  end

  def initialize(**args)
    super(**args)

    @autocomplete_component = EditableChamp::ComboSearchComponent.new(**args)
  end
end
