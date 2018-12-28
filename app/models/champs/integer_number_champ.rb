class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: { only_integer: true, allow_nil: true, allow_blank: true }

  def for_export
    value.present? ? value.to_i : nil
  end

  def for_api
    value.present? ? value.to_i : nil
  end
end
