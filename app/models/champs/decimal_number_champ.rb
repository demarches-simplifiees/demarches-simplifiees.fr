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
    value.present? ? value.to_f : nil
  end
end
