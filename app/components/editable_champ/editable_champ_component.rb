# frozen_string_literal: true

class EditableChamp::EditableChampComponent < ApplicationComponent
  def initialize(champs:, seen_at: nil)
    @champs, @seen_at = champs, seen_at
    @attribute = :value
  end

  def champ_component(form:, champ:)
    component_class(champ:).new(form:, champ:, seen_at: @seen_at)
  end

  private

  def has_label?(champ:)
    types_without_label = [
      TypeDeChamp.type_champs.fetch(:header_section),
      TypeDeChamp.type_champs.fetch(:explication),
      TypeDeChamp.type_champs.fetch(:repetition),
      TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
    ]
    !types_without_label.include?(champ.type_champ)
  end

  def component_class(champ:)
    "EditableChamp::#{champ.type_champ.camelcase}Component".constantize
  end

  def html_options(component:, champ:)
    {
      class: class_names(
        {
          'editable-champ': true,
          "editable-champ-#{champ.type_champ}": true,
          component.dsfr_group_classname => true
        }.merge(component.input_group_error_class_names)
      ),
      data: { controller: stimulus_controller(champ:), **data_dependent_conditions(champ:), **stimulus_values(champ:) }
    }
      .deep_merge(component.fieldset_aria_opts)
      .deep_merge(component.fieldset_error_opts)
  end

  def fieldset_element_attributes(champ:)
    {
      id: champ.input_group_id,
      "hidden": !champ.visible?
    }
  end

  def stimulus_values(champ:)
    if champ.waiting_for_external_data?
      {
        turbo_poll_url_value: turbo_poll_url_value(champ:),
        turbo_poll_interval_value: 2_000,
        turbo_poll_strategy_value: 'fixed'
      }
    else
      {}
    end
  end

  def turbo_poll_url_value(champ:)
    if champ.private?
      annotation_instructeur_dossier_path(champ.dossier.procedure, champ.dossier, champ.stable_id, row_id: champ.row_id)
    else
      champ_dossier_path(champ.dossier, champ.stable_id, row_id: champ.row_id)
    end
  end

  def stimulus_controller(champ:)
    if autosave_enabled?(champ:)
      # This is an editable champ. Lets find what controllers it might need.
      controllers = ['autosave']

      if champ.waiting_for_external_data?
        controllers << 'turbo-poll'
      end

      controllers.join(' ')
    end
  end

  def data_dependent_conditions(champ:)
    if champ.dependent_conditions?
      { "dependent-conditions": "true" }
    else
      {}
    end
  end

  def autosave_enabled?(champ:)
    !champ.carte? && !champ.repetition? && champ.fillable?
  end
end
