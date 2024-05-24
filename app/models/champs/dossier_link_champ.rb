class Champs::DossierLinkChamp < Champ
  # TODO: if: -> { validate_champ_value? || validation_context == :prefill }
  validate :value_integerable, if: -> { value.present? }, on: :prefill

  private

  def value_integerable
    Integer(value)
  rescue ArgumentError
    errors.add(:value, :not_integerable)
  end
end
