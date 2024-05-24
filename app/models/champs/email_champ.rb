class Champs::EmailChamp < Champs::TextChamp
  include EmailSanitizableConcern
  before_validation -> { sanitize_email(:value) }
  # TODO: if: -> { validate_champ_value? || validation_context == :prefill }
  validates :value, allow_blank: true, format: { with: StrictEmailValidator::REGEXP }, if: :validate_champ_value?
end
