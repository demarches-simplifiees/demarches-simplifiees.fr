class Champs::DecimalNumberChamp < Champ
  validates :value, numericality: {
    allow_nil: true,
    allow_blank: true,
    message: -> (object, data) {
      "« #{object.libelle} » " + object.errors.generate_message(data[:attribute].downcase, :not_a_number)
    }
  }

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
