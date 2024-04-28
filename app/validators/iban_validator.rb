# frozen_string_literal: true

require 'iban-tools'

class IbanValidator < ActiveModel::Validator
  def validate(record)
    if record.value.present?
      unless IBANTools::IBAN.valid?(record.value)
        record.errors.add :value, :invalid_iban
      end
    end
  end
end
