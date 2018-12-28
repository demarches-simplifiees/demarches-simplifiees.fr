class Champs::DecimalNumberChamp < Champ
  validates :value, numericality: { allow_nil: true, allow_blank: true }

  def for_export
    value.present? ? value.to_f : nil
  end

  def for_api
    value.present? ? value.to_f : nil
  end
end
