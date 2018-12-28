class Champs::LinkedDropDownListChamp < Champ
  delegate :primary_options, :secondary_options, to: 'type_de_champ.dynamic_type'

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
    pack_value(value, secondary_value)
  end

  def secondary_value=(value)
    pack_value(primary_value, value)
  end

  def main_value_name
    :primary_value
  end

  def to_s
    value.present? ? [primary_value, secondary_value].compact.join(' / ') : ""
  end

  def for_export
    value.present? ? "#{primary_value || ''};#{secondary_value || ''}" : nil
  end

  def mandatory_and_blank?
    mandatory? && (primary_value.blank? || secondary_value.blank?)
  end

  def search_terms
    [primary_value, secondary_value]
  end

  private

  def pack_value(primary, secondary)
    self.value = JSON.generate([primary, secondary])
  end
end
