# frozen_string_literal: true

class Champs::DropDownListChamp < Champ
  store_accessor :value_json, :other
  THRESHOLD_NB_OPTIONS_AS_RADIO = 5
  THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE = 20
  OTHER = '__other__'
  delegate :options_without_empty_value_when_mandatory, to: :type_de_champ
  validate :value_is_in_options, if: -> { validate_champ_value? && !(value.blank? || drop_down_other?) }

  def render_as_radios?
    drop_down_options.size <= THRESHOLD_NB_OPTIONS_AS_RADIO
  end

  def render_as_combobox?
    drop_down_options.size >= THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE
  end

  def html_label?
    !render_as_radios?
  end

  def legend_label?
    render_as_radios?
  end

  def selected
    other? ? OTHER : value
  end

  def other?
    if referentiel?
      (drop_down_other? && (other || (value.present? && referentiel_drop_down_options.map { _1.fetch('id') }.exclude?(value.to_i))))
    else
      drop_down_other? && (other || (value.present? && drop_down_options.exclude?(value)))
    end
  end

  def value=(value)
    if value == OTHER
      self.other = true
      write_attribute(:value, nil)
    else
      self.other = false
      write_attribute(:value, value)
    end
  end

  def value_other=(value)
    if other?
      write_attribute(:value, value)
    end
  end

  def value_other
    other? ? value : ""
  end

  private

  def value_is_in_options
    return if referentiel_mode? && value_is_in_referentiel_ids?
    return if drop_down_options.include?(value)

    errors.add(:value, :not_in_options)
  end

  def value_is_in_referentiel_ids?
    referentiel_drop_down_options.any? { _1['id'] == value.to_i }
  end
end
