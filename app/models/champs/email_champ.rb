class Champs::EmailChamp < Champs::TextChamp
  validates :value, format: { with: StrictEmailValidator::REGEXP }, if: :validate_champ_value?
end
