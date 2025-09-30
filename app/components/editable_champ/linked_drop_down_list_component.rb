# frozen_string_literal: true

class EditableChamp::LinkedDropDownListComponent < EditableChamp::EditableChampBaseComponent
  delegate :primary_value, to: :@champ
  # small trick here.
  # linked dropdown champ is a compound input. one input for primary, one for secondary.
  # focusable error does not point to the same input depending of the stage of the input.
  # if no primary selected, focusable error points to primary input which is named 'value'
  # if a primary is selected, focusable error points to secondary input which is now named 'value' (and primary input is now named 'primary_value')
  def focusable_primary_value_input_id
    if primary_value.blank?
      @champ.focusable_input_id(:value) # must be focusable when no primary is selected
    else
      @champ.focusable_input_id(:primary_value) # otherwise, use same as error name
    end
  end

  def focusable_secondary_value_input_id
    if primary_value.present?
      @champ.focusable_input_id(:value)
    else
      @champ.focusable_input_id(:not_visible_do_not_care)
    end
  end

  def dsfr_champ_container
    :div
  end

  def render?
    @champ.drop_down_options.any?
  end

  def select_options
    @champ.mandatory? ? { prompt: t('views.components.select_list') } : { include_blank: t('views.components.select_list') }
  end
end
