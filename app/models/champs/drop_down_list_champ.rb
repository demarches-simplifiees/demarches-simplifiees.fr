# frozen_string_literal: true

class Champs::DropDownListChamp < Champ
  belongs_to :referentiel_item, foreign_key: 'value', optional: true
  store_accessor :value_json, :other
  THRESHOLD_NB_OPTIONS_AS_RADIO = 5
  THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE = 20
  OTHER = '__other__'
  delegate :options_without_empty_value_when_mandatory, to: :type_de_champ
  validate :value_is_in_options, if: -> { !(value.blank? || drop_down_other?) && validate_champ_value_or_prefill? }

  def render_as_radios?
    options = referentiel? ? referentiel_drop_down_options : drop_down_options
    options.size <= THRESHOLD_NB_OPTIONS_AS_RADIO
  end

  def render_as_combobox?
    options = referentiel? ? referentiel_drop_down_options : drop_down_options
    options.size >= THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE
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
    drop_down_other? && (other || (value.present? && drop_down_options.exclude?(value)))
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

  def in?(options)
    options.include?(value)
  end

  private

  def value_is_in_options
    return if referentiel? && value_is_in_referentiel_ids?
    return if drop_down_options.include?(value)

    errors.add(:value, :not_in_options)
  end

  def value_is_in_referentiel_ids?
    referentiel_drop_down_options.map { _1['id'] }.include?(value.to_i)
  end
end
