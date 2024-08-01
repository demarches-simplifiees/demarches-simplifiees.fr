# frozen_string_literal: true

class ExpressionReguliereValidator < ActiveModel::Validator
  TIMEOUT = 1.second.freeze

  def validate(record)
    expression_reguliere = options[:expression_reguliere] || record.expression_reguliere
    expression_reguliere_error_message = options[:expression_reguliere_error_message] || record.expression_reguliere_error_message

    if record.value.present?
      if !record.value.match?(Regexp.new(expression_reguliere, timeout: TIMEOUT))
        record.errors.add(:value, :invalid_regexp, expression_reguliere_error_message: expression_reguliere_error_message)
      end
    end
  rescue Regexp::TimeoutError
    record.errors.add(:expression_reguliere, :evil_regexp)
  end
end
