# frozen_string_literal: true

class FormattedChampValidator < ActiveModel::Validator
  def validate(record)
    if record.type_de_champ.formatted_mode == 'advanced'
      ExpressionReguliereValidator.new.validate(record)
    end

    if record.type_de_champ.formatted_mode == 'simple'
      SimpleFormattedChampValidator.new.validate(record)
    end
  end
end
