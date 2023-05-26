require 'iban-tools'

class IbanValidator < ActiveModel::Validator
  def validate(record)
    if record.value.present?
      unless IBANTools::IBAN.valid?(record.value)
        record.errors.add :value, message: record.errors.generate_message(:value, :invalid_iban)
      end
    end
  end
end
