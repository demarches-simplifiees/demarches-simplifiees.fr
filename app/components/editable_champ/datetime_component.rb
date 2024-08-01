# frozen_string_literal: true

class EditableChamp::DatetimeComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-input'
  end

  def formatted_value_for_datetime_locale
    if @champ.valid? && @champ.value.present?
      # convert to a format that the datetime-local input can understand
      DateTime.iso8601(@champ.value).strftime('%Y-%m-%dT%H:%M')
    else
      @champ.value
    end
  end
end
