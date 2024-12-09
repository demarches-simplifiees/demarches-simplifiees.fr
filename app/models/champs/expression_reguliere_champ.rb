# frozen_string_literal: true

class Champs::ExpressionReguliereChamp < Champ
  validates_with ExpressionReguliereValidator, if: :validate_champ_value?
end
