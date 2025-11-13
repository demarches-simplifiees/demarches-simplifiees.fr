# frozen_string_literal: true

class Champs::LinkedDropDownListChamp < Champ
  delegate :primary_options, :secondary_options, to: :type_de_champ

  def primary_value
    if type_de_champ.champ_blank?(self)
      ''
    else
      JSON.parse(value)[0]
    end
  end

  def secondary_value
    if type_de_champ.champ_blank?(self)
      ''
    else
      JSON.parse(value)[1]
    end
  end

  def primary_value=(value)
    if value.blank?
      pack_value("", "")
    else
      new_secondary_value = secondary_options[value]&.include?(secondary_value) ? secondary_value : ""
      pack_value(value, new_secondary_value)
    end
  end

  def secondary_value=(value)
    new_secondary_value = secondary_options[primary_value]&.include?(value) ? value : ""
    pack_value(primary_value, new_secondary_value)
  end

  def main_value_name
    :primary_value
  end

  def search_terms
    [primary_value, secondary_value]
  end

  def has_secondary_options_for_primary?
    primary_value.present? && secondary_options[primary_value]&.any?(&:present?)
  end

  private

  def pack_value(primary, secondary)
    self.value = JSON.generate([primary, secondary])
  end
end
