class Champs::DecimalNumberChamp < Champ
  validates :value, numericality: { allow_nil: true }

  def value_for_export
    value.to_f
  end
end
