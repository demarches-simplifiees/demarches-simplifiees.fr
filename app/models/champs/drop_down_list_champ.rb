# frozen_string_literal: true

class Champs::DropDownListChamp < Champ
  store_accessor :value_json, :other, :referentiel
  THRESHOLD_NB_OPTIONS_AS_RADIO = 5
  THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE = 20
  OTHER = '__other__'
  delegate :options_without_empty_value_when_mandatory, to: :type_de_champ
  validate :value_is_in_options, if: -> { validate_champ_value? && !(value.blank? || drop_down_other?) }

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
      self.referentiel = nil if self.referentiel?
      write_attribute(:value, nil)
    else
      self.other = false
      self.referentiel = set_referentiel_from(value) if self.referentiel? && value
      write_attribute(:value, value)
    end
  end

  def set_referentiel_from(value)
    referentiel_item = ReferentielItem.find(value)
    { data: referentiel_item.data }
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

  def referentiel_item_first_column
    return nil if self.value_json&.dig("referentiel").nil?
    # a checker
    self.value_json["referentiel"].fetch("data").first
  end

  def referentiel_item_data
    return nil if self.value_json&.dig("referentiel").nil?
    self.value_json["referentiel"].fetch("data")
  end

  def referentiel_item_first_column_value
    referentiel_item_first_column&.last
  end

  def referentiel_headers
    ReferentielItem.find(value).referentiel.headers
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
