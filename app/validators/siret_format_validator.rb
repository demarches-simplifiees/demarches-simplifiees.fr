class SiretFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !format_is_valid(value)
      record.errors.add(attribute, :format)
    end

    if !luhn_passed(value)
      record.errors.add(attribute, :checksum)
    end
  end

  private

  def format_is_valid(value)
    value&.match?(/^\d{14}$/)
  end

  def luhn_passed(value)
    value.present? && (luhn_checksum(value) % 10 == 0)
  end

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
