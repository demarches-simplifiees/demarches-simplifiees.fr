class Champs::ExpressionReguliereChamp < Champ
  validates_with ExpressionReguliereValidator, if: :validate_champ_value_or_prefill?
end
