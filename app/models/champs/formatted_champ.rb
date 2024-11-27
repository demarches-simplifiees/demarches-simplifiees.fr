# frozen_string_literal: true

class Champs::FormattedChamp < Champ
  validates_with ExpressionReguliereValidator, if: :validate_champ_value_or_prefill?
end
