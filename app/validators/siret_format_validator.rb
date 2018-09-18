class SiretFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !value&.match?(/^\d{14}$/)
      record.errors.add(attribute, :format)
    end

    if value.present? && (luhn_checksum(value) % 10 != 0)
      record.errors.add(attribute, :checksum)
    end
  end

  private

  def luhn_checksum(value)
    accum = 0

    value.reverse.each_char.map(&:to_i).each_with_index do |digit, index|
      t = index.even? ? digit : digit * 2
      t = t - 9 if t >= 10
      accum += t
    end

    accum
  end
end
