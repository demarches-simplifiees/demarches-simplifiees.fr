class EditableChamp::ComboSearchComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def announce_template_id
    @announce_template_id ||= dom_id(@champ, "aria-announce-template")
  end

  # NOTE: because this template is called by `render_parent` from a child template,
  # as of ViewComponent 2.x translations virtual paths are not properly propagated
  # and we can't use the usual component namespacing. Instead we use global translations.
  def react_combo_props
    {
      screenReaderInstructions: t("combo_search_component.screen_reader_instructions"),
      announceTemplateId: announce_template_id
    }
  end
end
