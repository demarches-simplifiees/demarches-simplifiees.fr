class PasswordComplexityValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present? && ZxcvbnService.new(value).score < PASSWORD_COMPLEXITY_FOR_ADMIN
      record.errors.add(attribute, :not_strong)
    end
  end
end
