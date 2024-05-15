class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: {
    only_integer: true,
    allow_nil: true,
    allow_blank: true,
    message: -> (object, _data) {
      # i18n-tasks-use t('errors.messages.not_an_integer')
      object.errors.generate_message(:value, :not_an_integer)
    }
  }, if: :validate_champ_value_or_prefill?
end
