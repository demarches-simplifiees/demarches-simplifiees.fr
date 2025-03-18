# frozen_string_literal: true

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
  }, if: :validate_champ_value?

  validate :positive_value, if: -> { value.present? && validate_champ_value? }

  def format_value
    return if value.blank?

    self.value = value.gsub(/[[:space:]]/, "")
  end

  def positive_value
    if positive_number? && value.to_i.negative?
      # i18n-tasks-use t('errors.messages.not_positive')
      errors.add(:value, :not_positive)
    end
  end
end
