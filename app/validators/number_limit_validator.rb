# frozen_string_literal: true

class NumberLimitValidator < ActiveModel::Validator
  def validate(record)
    return if record.value.blank?
    positive_value(record)
    range_value(record)
  end

  private

  def positive_value(record)
    value = convert_to_number(record, 'value')

    if record.type_de_champ.positive_number? && value.negative?
      # i18n-tasks-use t('errors.messages.not_positive')
      record.errors.add(:value, :not_positive)
    end
  end

  def range_value(record)
    value = convert_to_number(record, 'value')
    min = convert_to_number(record, 'min_number')
    max = convert_to_number(record, 'max_number')

    if record.type_de_champ.range_number?
      if min.present? && max.present? && not_in_range(min, max, value)
        # i18n-tasks-use t('errors.messages.not_in_range')
        record.errors.add(:value, :not_in_range, min:, max:)
      elsif min.present? && value < min
        # i18n-tasks-use t('errors.messages.limit_min')
        record.errors.add(:value, :limit_min, min:)
      elsif max.present? && value > max
        # i18n-tasks-use t('errors.messages.limit_max')
        record.errors.add(:value, :limit_max, max:)
      end
    end
  end

  def convert_to_number(record, champ)
    return '' if record.method(champ).call.blank?
    record.type == "Champs::IntegerNumberChamp" ? record.method(champ).call.to_i : record.method(champ).call.to_f
  end

  def not_in_range(min, max, value)
    !(min <= value && value <= max)
  end
end
