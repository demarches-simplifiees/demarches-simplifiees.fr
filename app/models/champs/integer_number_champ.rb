class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: { only_integer: true, allow_nil: true, allow_blank: true }

  def for_export
    processed_value
  end

  def for_api
    processed_value
  end

  private

  def processed_value
    value&.to_i
  end
end
