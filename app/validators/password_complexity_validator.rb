# frozen_string_literal: true

class PasswordComplexityValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present? && ZxcvbnService.new(value).score < record.min_password_complexity
      record.errors.add(attribute, :not_strong)
    end
  end
end
