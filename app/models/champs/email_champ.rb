class Champs::EmailChamp < Champs::TextChamp
  include EmailSanitizableConcern
  before_validation -> { sanitize_email(:value) }
  validates :value, format: { with: StrictEmailValidator::REGEXP }, if: :validate_champ_value?
end
