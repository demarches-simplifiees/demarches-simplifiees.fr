# frozen_string_literal: true

class DateLimitValidator < ActiveModel::Validator
  def validate(champ)
    return if champ.value.blank?
    validate_in_past(champ) if champ.type_de_champ.date_in_past?
    validate_in_range(champ) if champ.type_de_champ.range_date?
  end

  private

  def validate_in_past(champ)
    # value has a timezone, it has to be converted to a date before the comparison
    date = date_or_datetime(champ, champ.value).to_date

    if date >= Date.today
      # i18n-tasks-use t('errors.messages.date_in_past')
      champ.errors.add(:value, :date_in_past)
    end
  end

  def validate_in_range(champ)
    value = date_or_datetime(champ, champ.value)
    start_date = date_or_datetime(champ, champ.start_date)
    end_date = date_or_datetime(champ, champ.end_date)

    if start_date.present? && end_date.present? && not_in_range(start_date, end_date, value)
      # i18n-tasks-use t('errors.messages.not_in_range_date')
      champ.errors.add(:value, :not_in_range_date, start_date: I18n.l(start_date, format: '%d %B %Y'), end_date: I18n.l(end_date, format: '%d %B %Y'))
    elsif start_date.present? && value < start_date
      # i18n-tasks-use t('errors.messages.limit_start_date')
      champ.errors.add(:value, :limit_start_date, start_date: I18n.l(start_date, format: '%d %B %Y'))
    elsif end_date.present? && value > end_date
      # i18n-tasks-use t('errors.messages.limit_end_date')
      champ.errors.add(:value, :limit_end_date, end_date: I18n.l(end_date, format: '%d %B %Y'))
    end
  end

  def date_or_datetime(champ, value)
    return '' if value.blank?
    champ.date? ? value.to_date : value.to_datetime
  rescue Date::Error
    nil
  end

  def not_in_range(start_date, end_date, value)
    !(start_date..end_date).cover?(value)
  end
end
