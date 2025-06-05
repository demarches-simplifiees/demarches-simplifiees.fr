# frozen_string_literal: true

class Champs::LinkedDropDownListChamp < Champ
  delegate :primary_options, :secondary_options, to: :type_de_champ

  def primary_value
    if value.present?
      JSON.parse(value)[0]
    else
      ''
    end
  end

  def secondary_value
    if value.present?
      JSON.parse(value)[1]
    else
      ''
    end
  end

  def primary_value=(value)
    if value.blank?
      pack_value("", "")
    else
      pack_value(value, secondary_value)
    end
  end

  def secondary_value=(value)
    pack_value(primary_value, value)
  end

  def main_value_name
    :primary_value
  end

  def blank?
    primary_value.blank? ||
      (has_secondary_options_for_primary? && secondary_value.blank?)
  end

  def search_terms
    [primary_value, secondary_value]
  end

  def has_secondary_options_for_primary?
    primary_value.present? && secondary_options[primary_value]&.any?(&:present?)
  end

  def in?(options)
    options.include?(primary_value) || options.include?(secondary_value)
  end

  def remove_option(options, touch = false)
    if touch
      update(value: nil)
    else
      update_column(:value, nil)
    end
  end

  private

  def pack_value(primary, secondary)
    self.value = JSON.generate([primary, secondary])
  end
end
