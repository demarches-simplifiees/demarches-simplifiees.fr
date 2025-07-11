# frozen_string_literal: true

class EditableChamp::LinkedDropDownListComponent < EditableChamp::EditableChampBaseComponent
  delegate :primary_value, to: :@champ
  # small trick here.
  # linked dropdown champ is a compound input. one input for primary, one for secondary.
  # focusable error does not point to the same input.
  # if no primary selected, focusable error points to primary input
  # if a primary is selected, focusable error points to secondary input
  def focusable_primary_value_input_id
    if primary_value.blank?
      @champ.focusable_input_id(:value) # must be focusable when no departement is selected
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
    :fieldset
  end

  def render?
    @champ.drop_down_options.any?
  end

  private

  def secondary_label
    secondary_label_text + secondary_label_mandatory
  end

  def secondary_label_text
    @champ.drop_down_secondary_libelle.presence || "Valeur secondaire dépendant de la première"
  end

  def secondary_label_mandatory
    @champ.mandatory? ? tag.span(' *', class: 'mandatory') : ''
  end
end
