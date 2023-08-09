class EditableChamp::EditableChampComponent < ApplicationComponent
  def initialize(form:, champ:, seen_at: nil)
    @form, @champ, @seen_at = form, champ, seen_at
  end

  private

  def has_label?(champ)
    types_without_label = [TypeDeChamp.type_champs.fetch(:header_section), TypeDeChamp.type_champs.fetch(:explication)]
    !types_without_label.include?(@champ.type_champ)
  end

  def component_class
    "EditableChamp::#{@champ.type_champ.camelcase}Component".constantize
  end

  def html_options
    {
      class: class_names(
        "editable-champ-#{@champ.type_champ}": true,
        "hidden": !@champ.visible?
      ),
      id: @champ.input_group_id,
      data: { controller: stimulus_controller, **data_dependent_conditions }
    }
  end

  def stimulus_controller
    if !@champ.block? && @champ.fillable?
      # This is an editable champ. Lets find what controllers it might need.
      controllers = ['autosave']

      controllers.join(' ')
    end
  end

  def data_dependent_conditions
    if @champ.dependent_conditions?
      { "dependent-conditions": "true" }
    else
      {}
    end
  end
end
