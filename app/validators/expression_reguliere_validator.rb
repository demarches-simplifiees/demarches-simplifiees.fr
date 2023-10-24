class ExpressionReguliereValidator < ActiveModel::Validator
  TIMEOUT = 1.second.freeze

  def validate(record)
    if record.value.present?
      if !record.value.match?(Regexp.new(record.expression_reguliere, timeout: TIMEOUT))
        record.errors.add(:value, :invalid_regexp, expression_reguliere_error_message: record.expression_reguliere_error_message)
      end
    end
  rescue Regexp::TimeoutError
    record.errors.add(:expression_reguliere, :evil_regexp)
  end
end
