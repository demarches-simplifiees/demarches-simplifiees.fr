# frozen_string_literal: true

class IbanService
  class << self
    def bic(iban)
      return unless IBANTools::IBAN.valid?(iban)
      iban = iban.gsub(/\s+/, '')
      country = iban[0, 2]
      bban = iban[4..-1]
      bic_code_index[country].find { bban.start_with?(_1[:riad_code][2..-1]) }
    end

    private

    def bic_code_index
      Rails.cache.fetch('bic_code_index', expires_in: 1.week) do
        JSON.parse(Rails.root.join('lib', 'data', 'iban', 'bic.json').read, symbolize_names: true).group_by { _1[:country].upcase }
      end
    end
  end
end
