# frozen_string_literal: true

class DateLimitValidator < ActiveModel::Validator
  def validate(record)
    return if record.value.blank?
    in_past_value(record)
    range_value(record)
  end

  private

  def in_past_value(record)
    # value has a timezone, it has to be converted to a date before the comparison
    date = date_or_datetime(record, 'value').to_date

    if record.type_de_champ.date_in_past? && date >= Date.today
      # i18n-tasks-use t('errors.messages.date_in_past')
      record.errors.add(:value, :date_in_past)
    end
  end

  def range_value(record)
    value = date_or_datetime(record, 'value')
    start_date = date_or_datetime(record, 'start_date')
    end_date = date_or_datetime(record, 'end_date')

    if record.type_de_champ.range_date?
      if start_date.present? && end_date.present? && not_in_range(start_date, end_date, value)
        # i18n-tasks-use t('errors.messages.not_in_range_date')
        record.errors.add(:value, :not_in_range_date, start_date: I18n.l(start_date, format: '%d %B %Y'), end_date: I18n.l(end_date, format: '%d %B %Y'))
      elsif start_date.present? && value < start_date
        # i18n-tasks-use t('errors.messages.limit_start_date')
        record.errors.add(:value, :limit_start_date, start_date: I18n.l(start_date, format: '%d %B %Y'))
      elsif end_date.present? && value > end_date
        # i18n-tasks-use t('errors.messages.limit_end_date')
        record.errors.add(:value, :limit_end_date, end_date: I18n.l(end_date, format: '%d %B %Y'))
      end
    end
  end

  def date_or_datetime(record, attribute)
    return '' if record.method(attribute).call.blank?
    record.date? ? record.method(attribute).call.to_date : record.method(attribute).call.to_datetime
  rescue Date::Error
    nil
  end

  def not_in_range(start_date, end_date, value)
    !(start_date..end_date).cover?(value)
  end
end
