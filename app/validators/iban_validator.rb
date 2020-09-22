require 'iban-tools'

class IbanValidator < ActiveModel::Validator
  def validate(record)
    if record.value.present?
      unless IBANTools::IBAN.valid?(record.value)
        record.errors.add :iban, record.errors.generate_message(:value, :invalid)
      end
    end
  end
end
