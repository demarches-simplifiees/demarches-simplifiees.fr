# frozen_string_literal: true

class NumberLimitValidator < ActiveModel::Validator
  def validate(record)
    positive_value(record)
  end

  private

  def positive_value(record)
    value = record.type == "Champs::IntegerNumberChamp" ? record.value.to_i : record.value.to_f

    if record.type_de_champ.positive_number? && value.negative?
      # i18n-tasks-use t('errors.messages.not_positive')
      record.errors.add(:value, :not_positive)
    end
  end
end
