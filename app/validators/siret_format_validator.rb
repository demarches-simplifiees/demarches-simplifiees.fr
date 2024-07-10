class SiretFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !format_is_valid(value)
      record.errors.add(attribute, :length)
    elsif !luhn_passed(value)
      record.errors.add(attribute, :checksum)
    end
  end

  private

  LA_POSTE_SIREN = '356000000'

  def format_is_valid(value)
    case value&.length
    when 6
      value.match?(/^[0-9A-Z]\d{5}$/)
    when 9
      value.match?(/^[0-9A-Z]\d{8}$/)
    when 14
      value.match?(/^\d{14}$/)
    else
      false
    end
  end

  def luhn_passed(value)
    # Do not enforce Luhn for La Poste SIRET numbers, the only exception to this rule
    siret_is_attached_to_la_poste(value) || siret_is_numero_tahiti(value) || (luhn_checksum(value) % 10 == 0)
  end

  def siret_is_attached_to_la_poste(value)
    value[0..8] == LA_POSTE_SIREN
  end

  def siret_is_numero_tahiti(value)
    return value.length == 6 || value.length == 9
  end

  def luhn_checksum(value)
    value.reverse.each_char.map(&:to_i).map.with_index do |digit, index|
      t = index.even? ? digit : digit * 2
      t < 10 ? t : t - 9
    end.sum
  end
end
