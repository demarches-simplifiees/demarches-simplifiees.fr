class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: { only_integer: true, allow_nil: true, allow_blank: true }

  def value_for_export
    value.to_i
  end
end
