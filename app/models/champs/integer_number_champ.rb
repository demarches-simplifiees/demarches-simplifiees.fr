class Champs::IntegerNumberChamp < Champ
  before_validation :format_value

  validates :value, numericality: {
    only_integer: true,
    allow_nil: true,
    allow_blank: true,
    message: -> (object, _data) {
      # i18n-tasks-use t('errors.messages.not_an_integer')
      object.errors.generate_message(:value, :not_an_integer)
    }
  }, if: :validate_champ_value_or_prefill?

  validate :min_max_validation, if: :validate_champ_value_or_prefill?

  def min_max_validation
    return if value.blank?

    if type_de_champ.min.present? && value.to_i < type_de_champ.min.to_i
      errors.add(:value, :greater_than_or_equal_to, value: value, count: type_de_champ.min.to_i)
    end
    if type_de_champ.max.present? && value.to_i > type_de_champ.max.to_i
      errors.add(:value, :less_than_or_equal_to, value: value, count: type_de_champ.max.to_i)
    end
  end

  def format_value
    return if value.blank?

    self.value = value.gsub(/[[:space:]]/, "")
  end
end
