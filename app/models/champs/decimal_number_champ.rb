class Champs::DecimalNumberChamp < Champ
  before_validation :format_value
  validates :value, format: {
    with: /\A-?[0-9]+([\.,][0-9]{1,3})?\z/,
    allow_nil: true,
    allow_blank: true,
    message: -> (object, _data) {
      # i18n-tasks-use t('errors.messages.not_a_float')
      object.errors.generate_message(:value, :not_a_float)
    }
  }, numericality: {
    allow_nil: true,
    allow_blank: true,
    message: -> (object, _data) {
      object.errors.generate_message(:value, :not_a_number)
    }
  }, if: -> { validate_champ_value? || validation_context == :prefill }

  def for_export(path = :value)
    processed_value
  end

  def for_api
    processed_value
  end

  private

  def format_value
    return if value.blank?

    self.value = value.tr(",", ".")
  end

  def processed_value
    return unless valid_champ_value?

    value&.to_f
  end
end
