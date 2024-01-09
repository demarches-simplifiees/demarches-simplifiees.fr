class Champs::CheckboxChamp < Champs::BooleanChamp
  def for_export
    true? ? 'on' : 'off'
  end

  def mandatory_blank?
    mandatory? && (blank? || !true?)
  end

  # TODO remove when normalize_checkbox_values is over
  def true?
    value_with_legacy == TRUE_VALUE
  end

  private

  # TODO remove when normalize_checkbox_values is over
  def value_with_legacy
    value == 'on' ? TRUE_VALUE : value
  end
end
