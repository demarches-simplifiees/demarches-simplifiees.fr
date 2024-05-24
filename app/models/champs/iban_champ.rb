class Champs::IbanChamp < Champ
  # TODO: if: -> { validate_champ_value? || validation_context == :prefill }
  validates_with IbanValidator, if: :validate_champ_value?
  after_validation :format_iban

  def for_api
    to_s.gsub(/\s+/, '')
  end

  def for_api_v2
    for_api
  end

  private

  def format_iban
    self.value = value&.gsub(/\s+/, '')&.gsub(/(.{4})/, '\0 ')
  end
end
