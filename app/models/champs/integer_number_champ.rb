class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: {
    only_integer: true,
    allow_nil: true,
    allow_blank: true,
    message: -> (object, _data) {
      # i18n-tasks-use t('errors.messages.not_an_integer')
      object.errors.generate_message(:value, :not_an_integer)
    }
  }, if: -> { validate_champ_value? || validation_context == :prefill }

  def for_export(path = :value)
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
