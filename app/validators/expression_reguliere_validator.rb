# frozen_string_literal: true

class ExpressionReguliereValidator < ActiveModel::Validator
  TIMEOUT = 1.second.freeze

  def validate(record)
    return if record.value.blank?

    expression_reguliere = record.expression_reguliere.presence || options[:expression_reguliere]
    expression_reguliere_error_message = record.expression_reguliere_error_message.presence || options[:expression_reguliere_error_message]

    return if expression_reguliere.blank? # an admin may not yet filled regex on preview dossier

    if !record.value.match?(Regexp.new(expression_reguliere, timeout: TIMEOUT))
      record.errors.add(:value, :invalid_regexp, expression_reguliere_error_message: expression_reguliere_error_message)
    end
  rescue Regexp::TimeoutError
    record.errors.add(:expression_reguliere, :evil_regexp)
  end
end
