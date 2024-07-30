class Champs::NumbersAndLettersIdChamp < Champ
  before_validation :format_value

  validates :value,
    format: {
      with: /\A(\w| )+\z/,
      message: -> (object, _data) {
        # i18n-tasks-use t('errors.messages.not_a_numbers_and_letters_id')
        object.errors.generate_message(:value, :not_a_numbers_and_letters_id)
      }
    },
    if: -> { value.present? && validate_champ_value_or_prefill? }

  private

  def format_value
    return if value.blank?

    value.strip!
  end
end
