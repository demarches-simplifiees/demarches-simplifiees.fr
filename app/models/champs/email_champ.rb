class Champs::EmailChamp < Champs::TextChamp
  include EmailSanitizableConcern
  before_validation -> { sanitize_email(:value) }

  validates :value, allow_blank: true, format: { with: StrictEmailValidator::REGEXP }, if: :validate_champ_value_or_prefill?
end
