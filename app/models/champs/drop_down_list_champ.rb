# frozen_string_literal: true

class Champs::DropDownListChamp < Champ
  store_accessor :value_json, :other, :referentiel
  THRESHOLD_NB_OPTIONS_AS_RADIO = 5
  THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE = 20
  OTHER = '__other__'
  delegate :options_without_empty_value_when_mandatory, to: :type_de_champ
  validate :value_is_in_options, if: -> { validate_champ_value? && !(value.blank? || drop_down_other?) }
  before_save :store_referentiel

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
    drop_down_other? && (other || value_from_user?)
  end

  def value_from_user?
    return false if value.blank?
    if referentiel_mode?
      drop_down_options.map(&:second).exclude?(value.to_i)
    else
      drop_down_options.exclude?(value)
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

  def store_referentiel
    return if !self.referentiel_mode?
    if self.other?
      self.referentiel = nil
    else
      self.referentiel = referentiel_from(value) if value
    end
  end

  def referentiel_from(value)
    if value.present?
      referentiel_item = self.type_de_champ.referentiel.items.find(value)
      headers = referentiel_item.referentiel.headers
      { data: referentiel_item.data.merge(headers:) }
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

  def referentiel_item_data
    return nil if self.referentiel.nil?
    self.referentiel&.dig('data', 'row')
  end

  def referentiel_item_first_column_value
    return nil if self.referentiel.nil?
    header = self.referentiel&.dig('data', 'headers')&.first
    self.referentiel&.dig('data', 'row', header&.parameterize&.underscore)
  end

  def referentiel_headers
    referentiel&.dig('data', 'headers')
  end

  private

  def value_is_in_options
    return if referentiel_mode? && value_is_in_referentiel_ids?
    return if drop_down_options.include?(value)

    errors.add(:value, :not_in_options)
  end

  def value_is_in_referentiel_ids?
    drop_down_options.any? { _1.last == value.to_i }
  end
end
