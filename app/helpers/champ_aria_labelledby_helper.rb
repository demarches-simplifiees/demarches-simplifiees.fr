# frozen_string_literal: true

module ChampAriaLabelledbyHelper
  # There are 4 cases:

  # 1. A champ is in a repetition fieldset with multiple champ per row and a champ fieldset (ex: address)
  # - repetition fieldset
  #   - repetition legend
  #   - row fieldset
  #     - row legend
  #     - champ fieldset
  #       - champ legend
  #       - label
  #       - input => aria-labelledby="row-legend-id champ-legend-id label-id"

  # 2. A champ is in a repetition fieldset with multiple champ per row and no champ fieldset (ex: text)
  # - repetition fieldset
  #   - repetition legend
  #   - row fieldset(multiple champ per row)
  #     - row legend
  #     - label
  #     - input => aria-labelledby="row-legend-id label-id"

  # 3. A champ is in a repetition fieldset with one champ per row and a champ fieldset (ex: address)
  # - repetition fieldset
  #   - repetition legend
  #   - champ fieldset
  #     - champ legend
  #     - label
  #     - input => aria-labelledby="repetition-legend-id champ-legend-id label-id"

  # 4. A champ is in a repetition fieldset with one champ per row and no champ fieldset (ex: text)
  # - repetition fieldset
  #   - repetition legend
  #   - label
  #   - input => aria-labelledby="repetition-legend-id label-id"

  # It's up to the view component to decide if the container of the champ should be a fieldset or a div, so we cannot compute the aria-labelledby for the champ.

  def repetition_fieldset_legend_id(champ)
    return if champ.type_champ != TypeDeChamp.type_champs.fetch(:repetition)

    "#{champ.html_id}-legend"
  end

  def repetition_row_fieldset_legend_id(champ, row_id)
    return if row_id.blank?

    "#{champ.html_id}-#{row_id}-legend"
  end

  def champ_fieldset_legend_id(champ)
    "#{champ.html_id}-legend"
  end

  def input_label_id(champ, attribute = :value)
    [champ.html_id, attribute, "label"].compact.join('-').parameterize
  end
end
