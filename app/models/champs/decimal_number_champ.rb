class Champs::DecimalNumberChamp < Champ
  validates :value, numericality: { allow_nil: true, allow_blank: true }

  def for_export
    processed_value
  end

  def for_api
    processed_value
  end

  private

  def processed_value
    value&.to_f
  end
end
