# frozen_string_literal: true

class PasswordComplexityValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present? && ZxcvbnService.complexity(value) < PASSWORD_COMPLEXITY_FOR_ADMIN
      record.errors.add(attribute, :not_strong)
    end
  end
end
