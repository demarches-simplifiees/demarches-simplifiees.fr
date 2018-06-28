class Champs::LinkedDropDownListChamp < Champ
  attr_reader :primary_value, :secondary_value
  delegate :primary_options, :secondary_options, to: :type_de_champ

  after_initialize :unpack_value

  def unpack_value
    if value.present?
      primary, secondary = JSON.parse(value)
    else
      primary = secondary = ''
    end
    @primary_value ||= primary
    @secondary_value ||= secondary
  end

  def primary_value=(value)
    @primary_value = value
    pack_value
  end

  def secondary_value=(value)
    @secondary_value = value
    pack_value
  end

  def main_value_name
    :primary_value
  end

  def for_display
    [primary_value, secondary_value].compact.join(' / ')
  end

  def mandatory_and_blank?
    mandatory? && (primary_value.blank? || secondary_value.blank?)
  end

  private

  def value_for_export
    "#{primary_value || ''};#{secondary_value || ''}"
  end

  def pack_value
    self.value = JSON.generate([ primary_value, secondary_value ])
  end
end
