class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: {
    only_integer: true,
    allow_nil: true,
    allow_blank: true
  }
  validate :min_max_validation

  def min_max_validation
    return if value.blank?

    if type_de_champ.min.present? && value.to_i < type_de_champ.min.to_i
      errors.add(:value, :greater_than_or_equal_to, value: value, count: type_de_champ.min.to_i)
    end
    if type_de_champ.max.present? && value.to_i > type_de_champ.max.to_i
      errors.add(:value, :less_than_or_equal_to, value: value, count: type_de_champ.max.to_i)
    end
  end

  def for_export
    processed_value
  end

  def for_api
    processed_value
  end

  private

  def processed_value
    return unless valid_champ_value?

    value&.to_i
  end
end
