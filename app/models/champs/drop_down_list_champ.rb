class Champs::DropDownListChamp < Champ
  store_accessor :value_json, :other
  THRESHOLD_NB_OPTIONS_AS_RADIO = 5
  OTHER = '__other__'
  delegate :options_without_empty_value_when_mandatory, to: :type_de_champ

  validate :value_is_in_options, unless: -> { value.blank? || drop_down_other? }

  def render_as_radios?
    enabled_non_empty_options.size <= THRESHOLD_NB_OPTIONS_AS_RADIO
  end

  def options?
    drop_down_list_options?
  end

  def options
    if drop_down_other?
      drop_down_list_options + [["Autre", OTHER]]
    else
      drop_down_list_options
    end
  end

  def selected
    other? ? OTHER : value
  end

  def disabled_options
    drop_down_list_disabled_options
  end

  def enabled_non_empty_options
    drop_down_list_enabled_non_empty_options
  end

  def other?
    drop_down_other? && (other || (value.present? && drop_down_list_options.exclude?(value)))
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

  def remove_option(options)
    update_column(:value, nil)
  end

  private

  def value_is_in_options
    return if enabled_non_empty_options.include?(value)

    errors.add(:value, :not_in_options)
  end
end
