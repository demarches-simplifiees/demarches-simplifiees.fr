class Champs::ExpressionReguliereChamp < Champ
  # TODO: if: -> { validate_champ_value? || validation_context == :prefill }
  validates_with ExpressionReguliereValidator, if: :validate_champ_value?
end
