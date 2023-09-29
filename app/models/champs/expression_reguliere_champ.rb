class Champs::ExpressionReguliereChamp < Champ
  validates_with ExpressionReguliereValidator, if: -> { validation_context != :brouillon }
end
